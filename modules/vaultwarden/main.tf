terraform {
  required_providers {
    acme = {
      source = "vancluever/acme"
    }
  }
}
resource "azurerm_resource_group" "rg" {
  name     = "vaultwarden-rg"
  location = var.location
}
# Storage Account and File Share
resource "azurerm_storage_account" "storage_account" {
  name                     = "tikvaultwardenstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Zone redundant https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy
  account_kind             = "StorageV2"
  access_tier              = "Hot"
}

resource "azurerm_storage_share" "file_share" {
  name                 = "vaultwarden-data"
  storage_account_name = azurerm_storage_account.storage_account.name
  quota                = 10 # GB
}

# App Service (Linux Web App)
resource "azurerm_linux_web_app" "vaultwarden_app" {
  name                = "tik-vaultwarden-${terraform.workspace}"
  location            = var.location
  resource_group_name = var.app_service_plan_resource_group_name
  service_plan_id     = var.app_service_plan_id

  site_config {
    ftps_state = "Disabled"
    always_on  = false

    application_stack {
      docker_registry_url = "https://docker.io"
      docker_image_name   = "vaultwarden/server:latest"
    }
  }
  # Mount the Azure File Share
  storage_account {
    name         = "vaultwarden-persistent-storage"
    account_name = azurerm_storage_account.storage_account.name
    access_key   = azurerm_storage_account.storage_account.primary_access_key
    mount_path   = "/data"
    share_name   = azurerm_storage_share.file_share.name
    type         = "AzureFiles"
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                       = "80"

    # Vaultwarden Environment Variables
    ADMIN_TOKEN     = var.admin_api_key
    DOMAIN          = "https://${local.fqdn}"
    SIGNUPS_ALLOWED = "false"

    # SMTP configuration 
    SMTP_SECURITY = "force_tls"
    SMTP_HOST     = var.smtp_host
    SMTP_FROM     = var.vaultwarden_smtp_from
    SMTP_PORT     = 465
    SMTP_USERNAME = var.vaultwarden_smtp_username
    SMTP_PASSWORD = var.vaultwarden_smtp_password
    # Database configuration
    DATABASE_URL = "postgresql://${var.db_username}:${var.db_password}@${var.db_host}:${var.db_port}/${var.db_name}"
  }
}


# A record for the web app
resource "azurerm_dns_a_record" "vaultwarden_a" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = data.dns_a_record_set.vaultwarden_dns_fetch.addrs
}

# Azure verification key
resource "azurerm_dns_txt_record" "vaultwarden_asuid" {
  name                = "asuid.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.vaultwarden_app.custom_domain_verification_id
  }
}


resource "azurerm_app_service_custom_hostname_binding" "vaultwarden_hostname_binding" {
  hostname            = local.fqdn
  app_service_name    = azurerm_linux_web_app.vaultwarden_app.name
  resource_group_name = var.app_service_plan_resource_group_name

  # Deletion may need manual work.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/11231
  # TODO: Add dependencies for creation
  depends_on = [
    azurerm_dns_a_record.vaultwarden_a,
    azurerm_dns_txt_record.vaultwarden_asuid
  ]
}
resource "random_password" "vaultwarden_cert_password" {
  length  = 48
  special = false
}

resource "acme_certificate" "vaultwarden_acme_cert" {
  account_key_pem          = var.acme_account_key
  common_name              = local.fqdn
  key_type                 = "2048" # RSA
  certificate_p12_password = random_password.vaultwarden_cert_password.result

  dns_challenge {
    provider = "azuredns"
    config = {
      AZURE_RESOURCE_GROUP = var.dns_resource_group_name
      AZURE_ZONE_NAME      = var.root_zone_name
    }
  }
}

resource "azurerm_app_service_certificate" "vaultwarden_cert" {
  name                = "tik-vaultwarden-cert-${terraform.workspace}"
  resource_group_name = var.app_service_plan_resource_group_name
  location            = var.location
  pfx_blob            = acme_certificate.vaultwarden_acme_cert.certificate_p12
  password            = acme_certificate.vaultwarden_acme_cert.certificate_p12_password
}

resource "azurerm_app_service_certificate_binding" "vaultwarden_cert_binding" {
  certificate_id      = azurerm_app_service_certificate.vaultwarden_cert.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.vaultwarden_hostname_binding.id
  ssl_state           = "SniEnabled"
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/14642#issuecomment-1084728235
# Currently, the azurerm provider doesn't give us the IP address, so we need to fetch it ourselves.
data "dns_a_record_set" "vaultwarden_dns_fetch" {
  host = azurerm_linux_web_app.vaultwarden_app.default_hostname
}
