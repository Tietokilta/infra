locals {
  db_name = "${var.environment}_ufositsit_db"
}

resource "random_password" "secret_key" {
  length  = 48
  special = false
}

resource "random_password" "admin_password" {
  length  = 32
  special = false
}

# Create postgres database
module "service_database" {
  source = "../service_database"

  db_name              = local.db_name
  postgres_server_id   = var.postgres_server_id
  postgres_server_fqdn = var.postgres_server_fqdn
}

resource "azurerm_linux_web_app" "ufositsit" {
  name                = "tik-ufositsit-${var.environment}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id

  https_only = true

  site_config {
    ftps_state = "Disabled"
    always_on  = true # payment confirmations and reminders are sent by a background thread

    application_stack {
      docker_registry_url      = "https://ghcr.io"
      docker_image_name        = "tietokilta/ufosits.it:latest"
      docker_registry_username = "TietokiltaAdmin"
      docker_registry_password = var.ghcr_token
      # The ghcr_token is a GitHub Personal Access Token (for TietokiltaAdmin account) with read:packages scope
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
    WEBSITES_PORT                       = 8080
    PORT                                = 8080
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"

    DATABASE_URL = format(
      "postgresql+psycopg://%s:%s@%s:5432/%s?sslmode=require",
      module.service_database.db_user,
      urlencode(module.service_database.db_password),
      var.postgres_server_fqdn,
      local.db_name
    )

    SECRET_KEY = random_password.secret_key.result

    ADMIN_PANEL_USER     = "admin"
    ADMIN_PANEL_PASSWORD = sha256(random_password.admin_password.result)

    EMAIL_SENDER  = "UFO-Joona <ufojoona@${module.mailgun.domain}>"
    SMTP_HOST     = module.mailgun.smtp_host
    SMTP_PORT     = tostring(module.mailgun.smtp_port)
    SMTP_USERNAME = module.mailgun.smtp_login
    SMTP_PASSWORD = module.mailgun.smtp_password

    EVENT_START             = var.event_start
    REGISTRATION_START      = var.registration_start
    REGISTRATION_END        = var.registration_end
    PAYMENT_DUE_DATE        = var.payment_due_date
    MAX_PARTICIPANTS        = var.max_participants
    PARTICIPATION_FEE_CENTS = var.participation_fee_cents
    CONTACT_TELEGRAM        = var.contact_telegram
    MOBILEPAY_NUMBER        = var.mobilepay_number
  }

  lifecycle {
    // image is deployed by the ufosits.it repo's GHA workflow
    ignore_changes = [
      site_config.0.application_stack.0.docker_image_name,
    ]
  }
}

module "app_service_hostname" {
  source                          = "../app_service_hostname"
  subdomain                       = "@"
  root_zone_name                  = var.root_zone_name
  custom_domain_verification_id   = azurerm_linux_web_app.ufositsit.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.ufositsit.name
  app_service_resource_group_name = var.resource_group_name
  app_service_location            = var.resource_group_location
  app_service_default_hostname    = azurerm_linux_web_app.ufositsit.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "tik-ufositsit-cert-${var.environment}"
  cloudflare_zone_id              = var.cloudflare_zone_id
  cloudflare_api_token            = var.cloudflare_api_token
}
