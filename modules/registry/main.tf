locals {
  postgres_db_name = "registry_${var.environment}"
}

# Create postgres database
module "service_database" {
  source = "../service_database"

  db_name                 = local.postgres_db_name
  postgres_server_id      = var.postgres_server_id
  postgres_admin_username = var.postgres_admin_username
  postgres_admin_password = var.postgres_admin_password
  postgres_server_fqdn    = var.postgres_server_fqdn
}

resource "azurerm_linux_web_app" "registry" {
  name                = "tik-registry-${var.environment}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id

  site_config {
    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/rekisteri:latest"
    }

    http2_enabled = true
  }

  logs {
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 100
      }
    }
  }

  https_only = true
  app_settings = {
    NODE_ENV = "production"

    DATABASE_URL = format(
      "postgres://%s:%s@%s:5432/%s",
      module.service_database.db_user,
      urlencode(module.service_database.db_password),
      var.postgres_server_fqdn,
      local.postgres_db_name
    )

    ADDRESS_HEADER = "X-Client-IP" # See: https://github.com/Azure/app-service-linux-docs/blob/master/Things_You_Should_Know/headers.md
    PUBLIC_URL     = "https://${module.app_service_hostname.fqdn}"

    MAILGUN_SENDER  = "TiK-rekisteri <noreply@${var.mailgun_domain}>"
    MAILGUN_API_KEY = var.mailgun_api_key
    MAILGUN_DOMAIN  = var.mailgun_domain
    MAILGUN_URL     = var.mailgun_url

    STRIPE_API_KEY        = var.stripe_api_key
    STRIPE_WEBHOOK_SECRET = var.stripe_webhook_secret

    # Passkey/WebAuthn Configuration
    RP_NAME   = "Tietokilta Rekisteri"
    RP_ID     = module.app_service_hostname.fqdn
    RP_ORIGIN = "https://${module.app_service_hostname.fqdn}"
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
  custom_domain_verification_id   = azurerm_linux_web_app.registry.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.registry.name
  app_service_resource_group_name = var.resource_group_name
  app_service_location            = var.resource_group_location
  app_service_default_hostname    = azurerm_linux_web_app.registry.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "tik-registry-cert-${var.environment}"
}
