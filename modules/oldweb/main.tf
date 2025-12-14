locals {
  db_name = "${var.environment}_oldweb_db"
}

resource "azurerm_resource_group" "rg" {
  name     = "oldweb-${var.environment}-rg"
  location = var.location
}

# Create postgres database
module "service_database" {
  source = "../service_database"

  db_name                 = local.db_name
  postgres_server_id      = var.postgres_server_id
  postgres_admin_username = var.postgres_admin_username
  postgres_admin_password = var.postgres_admin_password
  postgres_server_fqdn    = var.postgres_server_fqdn
}

# Database configuration moved to separate module
moved {
  from = azurerm_postgresql_flexible_server_database.oldweb_db
  to   = module.service_database.azurerm_postgresql_flexible_server_database.database
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
  lifecycle {
    prevent_destroy = true
  }
}

# File share
resource "azurerm_storage_share" "file_share" {
  name               = "oldweb-data"
  storage_account_id = azurerm_storage_account.storage_account.id
  quota              = 2 # GB
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
  name                = "tik-oldweb-${var.environment}-app"
  location            = var.location
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

    DB_USERNAME = module.service_database.db_user
    DB_PASSWORD = module.service_database.db_password
    DB_HOST     = var.postgres_server_fqdn
    DB_DATABASE = module.service_database.db_name
    DB_PORT     = 5432

  }
}

module "oldweb_hostname" {
  source = "../app_service_hostname"

  subdomain                       = var.subdomain
  root_zone_name                  = var.root_zone_name
  dns_resource_group_name         = var.dns_resource_group_name
  custom_domain_verification_id   = azurerm_linux_web_app.oldweb_backend.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.oldweb_backend.name
  app_service_resource_group_name = var.tikweb_rg_name
  app_service_location            = var.tikweb_rg_location
  app_service_default_hostname    = azurerm_linux_web_app.oldweb_backend.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "tik-oldweb-cert-${terraform.workspace}"
}
