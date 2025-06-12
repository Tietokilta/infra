locals {
  db_name = "${var.env_name}_ilmo_db"
}

resource "azurerm_postgresql_flexible_server_database" "ilmo_db_new" {
  name      = local.db_name
  server_id = var.postgres_server_id
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
    always_on  = false

    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/ilmomasiina:staging"
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

    MAIL_FROM = "noreply@${var.mailgun_domain}"

    ALLOW_ORIGIN = "*"

    # Paths from tikweb-web
    BASE_URL          = var.website_url
    EVENT_DETAILS_URL = "${var.website_url}/{lang}/events/{slug}"
    EDIT_SIGNUP_URL   = "${var.website_url}/{lang}/signups/{id}/{editToken}"
    ADMIN_URL         = "https://tik-ilmo-${var.env_name}-app.azurewebsites.net/admin"

    ICAL_UID_DOMAIN = "tietokilta.fi"

    BRANDING_ICAL_CALENDAR_NAME = "Tietokilta Staging"
    BRANDING_MAIL_FOOTER_TEXT   = "Ilmomasiina Staging - tietokilta.fi"
    BRANDING_MAIL_FOOTER_LINK   = "${var.website_url}/fi/events"
  }

  lifecycle {
    ignore_changes = [
      site_config.0.application_stack, # deployments are made outside of Terraform
    ]
  }
}
