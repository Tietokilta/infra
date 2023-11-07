locals {
  db_name = "${var.env_name}_cms_db"
}

resource "azurerm_postgresql_database" "tikweb_cms_db" {
  name                = local.db_name
  resource_group_name = var.resource_group_name
  server_name         = var.postgres_server_name
  charset             = "UTF8"
  collation           = "fi-FI"
}

resource "azurerm_postgresql_flexible_server_database" "tikweb_cms_db_new" {
  name      = "${local.db_name}-new"
  server_id = var.postgres_server_new_id
  collation = "fi_FI"
  charset   = "utf8"
}

resource "azurerm_linux_web_app" "tikweb_cms" {
  name                = "tikweb-${var.env_name}-app-cms"
  location            = var.tikweb_rg_location
  resource_group_name = var.tikweb_rg_name
  service_plan_id     = var.tikweb_app_plan_id

  https_only = true

  site_config {
    ftps_state = "Disabled"
    always_on  = true

    application_stack {
      docker_image     = "ghcr.io/tietokilta/strapi-cms"
      docker_image_tag = "latest"
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

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL = "https://ghcr.io"

    WEBSITES_PORT = 1337

    HOST              = "0.0.0.0"
    PORT              = 1337
    DATABASE          = "postgres"
    DATABASE_HOST     = var.postgres_server_fqdn
    DATABASE_PORT     = 5432
    DATABASE_NAME     = local.db_name
    DATABASE_USERNAME = "tietokilta@${var.postgres_server_host}"
    DATABASE_PASSWORD = var.postgres_admin_password
    DATABASE_SSL      = true
    ADMIN_JWT_SECRET  = var.strapi_admin_jwt_secret
    JWT_SECRET        = var.strapi_jwt_secret
    API_TOKEN_SALT    = var.strapi_api_token_salt
    APP_KEYS          = var.strapi_app_keys

    GITHUB_APP_ID              = "203379"
    GITHUB_APP_INSTALLATION_ID = "25896766"
    GITHUB_APP_KEY             = var.github_app_key

    UPLOADS_ACCOUNT_NAME   = var.uploads_storage_account_name
    UPLOADS_ACCOUNT_KEY    = var.uploads_storage_account_key
    UPLOADS_CONTAINER_NAME = var.uploads_container_name

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

  lifecycle {
    ignore_changes = [
      site_config.0.application_stack, # deployments are made outside of Terraform
    ]
  }
}
