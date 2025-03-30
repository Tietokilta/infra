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
}

# Create actual application
resource "azurerm_linux_web_app" "oldweb_backend" {
  name                = "tik-oldweb-${var.env_name}-app"
  location            = var.tikweb_rg_location
  resource_group_name = var.tikweb_rg_name
  service_plan_id     = var.tikweb_app_plan_id

  https_only = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    ftps_state = "Disabled"
    always_on  = true

    container_registry_use_managed_identity = true

    application_stack {
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
      docker_image_name   = "oldweb:latest"
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

  lifecycle {
    ignore_changes = [
      site_config.0.application_stack, # deployments are made outside of Terraform
    ]
  }
}

# Allow pulling from ACR
resource "azurerm_role_assignment" "web_app_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.oldweb_backend.identity[0].principal_id
}
