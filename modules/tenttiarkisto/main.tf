locals {
  db_name = "${var.env_name}_tentti_db"
}

resource "azurerm_resource_group" "tenttiarkisto_rg" {
  name     = "tenttiarkisto-${var.env_name}-rg"
  location = var.resource_group_location
}

resource "azurerm_postgresql_database" "tenttiarkisto_db" {
  name                = local.db_name
  resource_group_name = var.postgres_resource_group_name
  server_name         = var.postgres_server_name
  charset             = "UTF8"
  collation           = "fi-FI"
}

resource "azurerm_storage_account" "tenttiarkisto_storage_account" {
  name                      = "tenttiarkisto${var.env_name}sa"
  resource_group_name       = azurerm_resource_group.tenttiarkisto_rg.name
  location                  = azurerm_resource_group.tenttiarkisto_rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  allow_blob_public_access  = true
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
}

resource "azurerm_storage_container" "tenttiarkisto_storage_container" {
  name                  = "exams"
  storage_account_name  = azurerm_storage_account.tenttiarkisto_storage_account.name
  container_access_type = "blob"
}

resource "azurerm_app_service" "tenttiarkisto" {
  name                = "tenttiarkisto-${var.env_name}-app"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.tenttiarkisto_rg.name
  app_service_plan_id = var.aux_app_plan_id

  https_only = true

  site_config {
    ftps_state       = "Disabled"
    always_on        = true
    linux_fx_version = "DOCKER|ghcr.io/tietokilta/tenttiarkisto:latest"
  }

  logs {
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 100
      }
    }
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL = "https://ghcr.io"

    WEBSITES_PORT = 8000

    EXAM_ACCOUNT_NAME = azurerm_storage_account.tenttiarkisto_storage_account.name
    EXAM_ACCOUNT_KEY  = azurerm_storage_account.tenttiarkisto_storage_account.primary_access_key
    EXAM_CONTAINER    = azurerm_storage_container.tenttiarkisto_storage_container.name

    DB_NAME     = azurerm_postgresql_database.tenttiarkisto_db.name
    DB_USER     = "tietokilta@${var.postgres_server_host}"
    DB_PASSWORD = var.postgres_admin_password
    DB_HOST     = var.postgres_server_fqdn

    SECRET_KEY = var.django_secret_key

    ALLOWED_HOSTS = "tenttiarkisto-${var.env_name}-app.azurewebsites.net,tenttiarkisto.fi"
  }

  lifecycle {
    ignore_changes = [
      site_config.0.linux_fx_version, # deployments are made outside of Terraform
    ]
  }
}
