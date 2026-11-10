locals {
  postgres_db_name = "pakuvaraus_${var.environment}"
}

# Create postgres database
module "service_database" {
  source = "../service_database"

  db_name              = local.postgres_db_name
  postgres_server_id   = var.postgres_server_id
  postgres_server_fqdn = var.postgres_server_fqdn
}

resource "azurerm_linux_web_app" "pakuvaraus" {
  name                = "tik-pakuvaraus-${terraform.workspace}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id
  site_config {
    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/pakuvaraus:latest"
    }

    http2_enabled = true
  }
  logs {
    application_logs {
      file_system_level = "Information"
    }
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 100
      }
    }
  }
  https_only = true
  app_settings = {
    PORT             = 3000
    WEBSITES_PORT    = 3000
    BIND_ADDR        = "0.0.0.0"
    ALLOWED_ORIGINS  = "http://localhost:3000,https://tietokilta.fi"
    RUST_LOG         = "pakuvaraus=debug,tower_http=debug,axum::rejection=trace"
    RUST_LOG_STYLE   = "never"
    DATABASE_URL     = "postgresql://${module.service_database.db_user}:${urlencode(module.service_database.db_password)}@${var.postgres_server_fqdn}:5432/${module.service_database.db_name}"
    APPROVER_EMAIL   = "pakuvastaava@tietokilta.fi"
    EMAIL_ENABLED    = 0
    MAILGUN_URL      = "${module.mailgun.api_url_with_domain}/messages"
    MAILGUN_API_USER = "api"
    MAILGUN_API_KEY  = var.mailgun_api_key
    MAILGUN_TO       = "Pakuvastaava <pakuvastaava@tietokilta.fi>,invoice+1790346-8@to.nocfo.io"
    MAILGUN_FROM     = module.mailgun.mail_from
    # https://github.com/Azure/app-service-linux-docs/blob/master/Things_You_Should_Know/headers.md
    IP_EXTRACTOR_HEADER = "X-Client-IP"
  }
  lifecycle {
    // image is deployed by web-repos GHA workflow
    ignore_changes = [
      site_config.0.application_stack.0.docker_image_name,
    ]
  }
}

module "app_service_hostname" {
  source                          = "../app_service_hostname"
  subdomain                       = var.subdomain
  root_zone_name                  = var.root_zone_name
  custom_domain_verification_id   = azurerm_linux_web_app.pakuvaraus.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.pakuvaraus.name
  app_service_resource_group_name = var.resource_group_name
  app_service_location            = var.resource_group_location
  app_service_default_hostname    = azurerm_linux_web_app.pakuvarus.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "tik-pakuvaraus-cert-${terraform.workspace}"
  cloudflare_zone_id              = var.cloudflare_zone_id
  cloudflare_api_token            = var.cloudflare_api_token
}
