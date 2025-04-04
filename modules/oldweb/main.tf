terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "2.19.0"
    }
  }
}

locals {
  db_name = "${var.env_name}_oldweb_db"
  fqdn    = "${var.subdomain}.${var.root_zone_name}"
}

resource "azurerm_resource_group" "rg" {
  name     = "oldweb-${var.env_name}-rg"
  location = var.location
}

# Create postgres database
resource "azurerm_postgresql_flexible_server_database" "oldweb_db" {
  name      = local.db_name
  server_id = var.postgres_server_id
  charset   = "utf8"
}

# Storage account
resource "azurerm_storage_account" "storage_account" {
  name                     = "oldwebstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Zone redundant https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy
  account_kind             = "StorageV2"
  access_tier              = "Hot"
}

# File share
resource "azurerm_storage_share" "file_share" {
  name                 = "oldweb-data"
  storage_account_name = azurerm_storage_account.storage_account.name
  quota                = 2 # GB
}

resource "azurerm_container_registry" "acr" {
  name                = "oldwebContainerRegistry"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
  # Admin usage is not ideal, but it hopefully works
}

# Create actual application
resource "azurerm_linux_web_app" "oldweb_backend" {
  name                = "tik-oldweb-${var.env_name}-app"
  location            = var.tikweb_rg_location
  resource_group_name = var.tikweb_rg_name
  service_plan_id     = var.tikweb_app_plan_id

  https_only = true

  site_config {
    ftps_state = "Disabled"
    always_on  = true

    application_stack {
      docker_registry_url      = "https://${azurerm_container_registry.acr.login_server}"
      docker_image_name        = "oldweb:latest"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
    }
  }

  logs {
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 100
      }
    }
  }

  # Mount the Azure File Share for images and other attachments
  storage_account {
    name         = "oldweb-persistent-storage"
    account_name = azurerm_storage_account.storage_account.name
    access_key   = azurerm_storage_account.storage_account.primary_access_key
    mount_path   = "/app/public/page_attachments"
    share_name   = azurerm_storage_share.file_share.name
    type         = "AzureFiles"
  }

  # Configuration for oldweb
  app_settings = {
    WEBSITES_PORT = 3000
    PORT          = 3000

    DB_USERNAME = "tietokilta"
    DB_PASSWORD = var.postgres_admin_password
    DB_HOST     = var.postgres_server_fqdn
    DB_DATABASE = local.db_name
    DB_PORT     = 5432

  }
}

resource "azurerm_app_service_custom_hostname_binding" "oldweb_hostname_binding" {
  hostname            = local.fqdn
  app_service_name    = azurerm_linux_web_app.oldweb_backend.name
  resource_group_name = var.resource_group_name

  # Deletion may need manual work.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/11231
  # TODO: Add dependencies for creation
  depends_on = [
    azurerm_dns_a_record.oldweb_a,
    azurerm_dns_txt_record.oldweb_asuid
  ]
}
resource "random_password" "oldweb_cert_password" {
  length  = 48
  special = false
}

resource "acme_certificate" "oldweb_acme_cert" {
  account_key_pem          = var.acme_account_key
  common_name              = local.fqdn
  key_type                 = "2048" # RSA
  certificate_p12_password = random_password.oldweb_cert_password.result

  dns_challenge {
    provider = "azure"
    config = {
      AZURE_RESOURCE_GROUP = var.dns_resource_group_name
      AZURE_ZONE_NAME      = var.root_zone_name
    }
  }
}

resource "azurerm_app_service_certificate" "oldweb_cert" {
  name                = "tik-oldweb-cert-${terraform.workspace}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  pfx_blob            = acme_certificate.oldweb_acme_cert.certificate_p12
  password            = acme_certificate.oldweb_acme_cert.certificate_p12_password
}

resource "azurerm_app_service_certificate_binding" "oldweb_cert_binding" {
  certificate_id      = azurerm_app_service_certificate.oldweb_cert.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.oldweb_hostname_binding.id
  ssl_state           = "SniEnabled"
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/14642#issuecomment-1084728235
# Currently, the azurerm provider doesn't give us the IP address, so we need to fetch it ourselves.
data "dns_a_record_set" "oldweb_dns_fetch" {
  host = azurerm_linux_web_app.oldweb_backend.default_hostname
}
