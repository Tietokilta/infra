locals {
  db_name = "${var.environment}_ilmo_db"
  fqdn    = "${var.subdomain}.${var.root_zone_name}"
}

module "service_database" {
  source = "../service_database"

  db_name              = local.db_name
  postgres_server_id   = var.postgres_server_id
  postgres_server_fqdn = var.postgres_server_fqdn

  providers = {
    postgresql.admin = postgresql.admin
  }
}

resource "azurerm_linux_web_app" "ilmo_backend" {
  name                = "tik-ilmo-${var.environment}-app"
  location            = var.tikweb_rg_location
  resource_group_name = var.tikweb_rg_name
  service_plan_id     = var.tikweb_app_plan_id

  https_only = true

  site_config {
    ftps_state = "Disabled"
    always_on  = true

    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/ilmomasiina:latest"
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
    DB_DATABASE = module.service_database.db_name
    DB_USER     = module.service_database.db_user
    DB_PASSWORD = module.service_database.db_password

    ADMIN_REGISTRATION_ALLOWED = false

    NEW_EDIT_TOKEN_SECRET = var.edit_token_secret
    FEATHERS_AUTH_SECRET  = var.auth_jwt_secret

    MAIL_FROM       = module.mailgun.mail_from
    MAILGUN_API_KEY = var.mailgun_api_key
    MAILGUN_DOMAIN  = module.mailgun.domain

    ALLOW_ORIGIN = "*"

    # Paths from tikweb-web
    BASE_URL             = var.website_url
    EVENT_DETAILS_URL    = "${var.website_url}/{lang}/events/{slug}"
    EDIT_SIGNUP_URL      = "${var.website_url}/{lang}/signups/{id}/{editToken}"
    ADMIN_URL            = "https://${module.app_service_hostname.fqdn}/admin"
    COMPLETE_PAYMENT_URL = coalesce(var.complete_payment_url, "${var.website_url}/{lang}/signups/{id}/{editToken}")

    ICAL_UID_DOMAIN = "tietokilta.fi"

    BRANDING_ICAL_CALENDAR_NAME = "Tietokilta"
    BRANDING_MAIL_FOOTER_TEXT   = "Ilmomasiina - tietokilta.fi"
    BRANDING_MAIL_FOOTER_LINK   = "${var.website_url}/fi/events"

    STRIPE_SECRET_KEY     = var.stripe_secret_key
    STRIPE_WEBHOOK_SECRET = var.stripe_webhook_secret
    STRIPE_BRANDING_JSON = jsonencode({
      "background_color" = "#000000"
      "button_color"     = "#000000"
      "display_name"     = "Tietokilta ry"
      "font_family"      = "inconsolata"
    })
  }

  lifecycle {
    ignore_changes = [
      site_config.0.application_stack, # deployments are made outside of Terraform
    ]
  }
}

module "app_service_hostname" {
  source                          = "../app_service_hostname"
  subdomain                       = var.subdomain
  root_zone_name                  = var.root_zone_name
  dns_resource_group_name         = var.dns_resource_group_name
  custom_domain_verification_id   = azurerm_linux_web_app.ilmo_backend.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.ilmo_backend.name
  app_service_resource_group_name = var.tikweb_rg_name
  app_service_location            = var.tikweb_rg_location
  app_service_default_hostname    = azurerm_linux_web_app.ilmo_backend.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "tik-ilmo-cert-${var.environment}"
}
