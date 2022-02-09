locals {
  db_name = "${var.env_name}_ilmo_db"
}

resource "azurerm_postgresql_database" "ilmo_db" {
  name                = local.db_name
  resource_group_name = var.resource_group_name
  server_name         = var.postgres_server_name
  charset             = "UTF8"
  collation           = "fi-FI"
}


resource "azurerm_app_service_plan" "ilmo_backend_plan" {
  name                = "tik-ilmo-${var.env_name}-plan"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  kind     = "linux"
  reserved = true # Needs to be true for linux

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "ilmo_backend" {
  name                = "tik-ilmo-${var.env_name}-app"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  app_service_plan_id = azurerm_app_service_plan.ilmo_backend_plan.id

  https_only = true

  site_config {
    ftps_state       = "Disabled"
    always_on        = true
    linux_fx_version = "DOCKER|ghcr.io/tietokilta/ilmomasiina:latest"
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

    WEBSITES_PORT = 3000
    PORT          = 3000

    DB_DIALECT  = "postgres"
    DB_HOST     = var.postgres_server_fqdn
    DB_DATABASE = local.db_name
    DB_USER     = "tietokilta@${var.postgres_server_host}"
    DB_PASSWORD = var.postgres_admin_password

    ADMIN_REGISTRATION_ALLOWED = false

    NEW_EDIT_TOKEN_SECRET = var.edit_token_secret
    FEATHERS_AUTH_SECRET  = var.auth_jwt_secret

    MAIL_FROM       = "ilmo@tietokilta.fi"
    MAILGUN_API_KEY = var.mailgun_api_key
    MAILGUN_DOMAIN  = var.mailgun_domain

    BRANDING_MAIL_FOOTER_TEXT = ""
    BRANDING_MAIL_FOOTER_LINK = "ilmo.tietokilta.fi"
  }

  lifecycle {
    ignore_changes = [
      site_config.0.linux_fx_version, # deployments are made outside of Terraform
    ]
  }
}
