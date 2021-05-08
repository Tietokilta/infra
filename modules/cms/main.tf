locals {
  db_name = "${var.env_name}_cms_db"
}

resource "azurerm_postgresql_database" "tikweb_cms_db" {
  name                = local.db_name
  resource_group_name = var.resource_group_name
  server_name         = var.postgres_server_name
  charset             = "UTF8"
  collation           = "fi_FI"
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

resource "azurerm_app_service" "tikweb_cms" {
  name                = "tikweb-${var.env_name}-app-cms"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  app_service_plan_id = azurerm_app_service_plan.tikweb_plan.id

  https_only = true

  site_config {
    ftps_state       = "Disabled"
    always_on        = true
    linux_fx_version = "DOCKER|" # FIXME specify container
  }

  app_settings = {
    # FIXME: Are these needed for docker hub?
    # DOCKER_REGISTRY_SERVER_URL = ""
    # DOCKER_REGISTRY_SERVER_USERNAME = ""
    # DOCKER_REGISTRY_SERVER_PASSWORD = ""

    HOST              = "0.0.0.0"
    PORT              = 80
    DATABASE          = "postgres"
    DATABASE_HOST     = var.postgres_server_fqdn
    DATABASE_PORT     = 5432
    DATABASE_NAME     = local.db_name
    DATABASE_USERNAME = "tietokilta"
    DATABASE_PASSWORD = var.postgres_admin_password
    DATABASE_SSL      = true
    ADMIN_JWT_SECRET  = "badsecret" # FIXME: generate

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
