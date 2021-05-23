locals {
  db_name             = "${var.env_name}_cms_db"
  logs_container_name = "cms-logs"
  logs_container_url  = "${var.logs_sa_blob_endpoint}/${local.logs_container_name}"
}

resource "azurerm_postgresql_database" "tikweb_cms_db" {
  name                = local.db_name
  resource_group_name = var.resource_group_name
  server_name         = var.postgres_server_name
  charset             = "UTF8"
  collation           = "fi-FI"
}


resource "azurerm_app_service_plan" "tikweb_plan" {
  name                = "tikweb-${var.env_name}-plan"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  kind     = "linux"
  reserved = true # Needs to be true for linux

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_storage_container" "cms_logs" {
  name                 = local.logs_container_name
  storage_account_name = var.logs_sa_name
}

data "azurerm_storage_account_blob_container_sas" "logs_sas" {
  connection_string = var.logs_sa_connection_string
  container_name    = azurerm_storage_container.cms_logs.name
  https_only        = true

  start  = "2021-01-01"
  expiry = "2069-01-01"

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }
}

resource "azurerm_app_service" "tikweb_cms" {
  name                = "tikweb-${var.env_name}-app-cms"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  app_service_plan_id = azurerm_app_service_plan.tikweb_plan.id

  https_only = true

  site_config {
    ftps_state       = "Disabled"
    always_on        = true
    linux_fx_version = "DOCKER|ghcr.io/tietokilta/strapi-cms:latest"
  }

  logs {
    application_logs {
      azure_blob_storage {
        level             = "Verbose"
        sas_url           = "${local.logs_container_url}?${data.azurerm_storage_account_blob_container_sas.logs_sas.sas}"
        retention_in_days = 7
      }
    }

    detailed_error_messages_enabled = true
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL = "https://ghcr.io"

    WEBSITES_PORT = 1337

    HOST              = "0.0.0.0"
    PORT              = 1337
    DATABASE          = "postgres"
    DATABASE_HOST     = var.postgres_server_fqdn
    DATABASE_PORT     = 5432
    DATABASE_NAME     = local.db_name
    DATABASE_USERNAME = "tietokilta"
    DATABASE_PASSWORD = var.postgres_admin_password
    DATABASE_SSL      = true
    ADMIN_JWT_SECRET  = var.strapi_admin_jwt_secret

    #Strapi env
    STRAPI_DISABLE_UPDATE_NOTIFICATION = false
    STRAPI_HIDE_STARTUP_MESSAGE        = false
    STRAPI_TELEMETRY_DISABLED          = false
    STRAPI_LOG_TIMESTAMP               = false
    STRAPI_LOG_LEVEL                   = "info"
    STRAPI_LOG_FORCE_COLOR             = true
    STRAPI_LOG_PRETTY_PRINT            = true
    BROWSER                            = true
  }
}
