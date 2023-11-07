locals {
  db_name = "${var.env_name}_ilmo_db"
  fqdn    = "${var.subdomain}.${var.root_zone_name}"
}

resource "azurerm_postgresql_database" "ilmo_db" {
  name                = local.db_name
  resource_group_name = var.resource_group_name
  server_name         = var.postgres_server_name
  charset             = "UTF8"
  collation           = "fi-FI"
}

resource "azurerm_postgresql_flexible_server_database" "ilmo_db_new" {
  name      = local.db_name
  server_id = var.postgres_server_new_id
  charset   = "utf8"
}


resource "azurerm_linux_web_app" "ilmo_backend" {
  name                = "tik-ilmo-${var.env_name}-app"
  location            = var.tikweb_rg_location
  resource_group_name = var.tikweb_rg_name
  service_plan_id     = var.tikweb_app_plan_id

  https_only = true

  site_config {
    ftps_state = "Disabled"
    always_on  = true

    application_stack {
      docker_image     = "ghcr.io/tietokilta/ilmomasiina"
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

    WEBSITES_PORT = 3000
    PORT          = 3000

    DB_DIALECT  = "postgres"
    DB_HOST     = var.postgres_server_fqdn
    DB_SSL      = true
    DB_DATABASE = local.db_name
    DB_USER     = "tietokilta"
    DB_PASSWORD = var.postgres_admin_password

    ADMIN_REGISTRATION_ALLOWED = false

    NEW_EDIT_TOKEN_SECRET = var.edit_token_secret
    FEATHERS_AUTH_SECRET  = var.auth_jwt_secret

    MAIL_FROM       = "noreply@${var.mailgun_domain}"
    MAILGUN_API_KEY = var.mailgun_api_key
    MAILGUN_DOMAIN  = var.mailgun_domain

    ALLOW_ORIGIN = "*"

    # Paths from tikweb-frontend
    BASE_URL          = var.website_events_url
    EVENT_DETAILS_URL = "${var.website_events_url}/{slug}"
    EDIT_SIGNUP_URL   = "${var.website_events_url}/ilmo/{id}/{editToken}"

    BRANDING_MAIL_FOOTER_TEXT = "Ilmomasiina"
    BRANDING_MAIL_FOOTER_LINK = var.website_events_url
  }

  lifecycle {
    ignore_changes = [
      site_config.0.application_stack, # deployments are made outside of Terraform
    ]
  }
}
