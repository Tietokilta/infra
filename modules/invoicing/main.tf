resource "azurerm_linux_web_app" "invoice_generator" {
  name                = "tikweb-invoice-generator-${terraform.workspace}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id
  site_config {
    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/laskugeneraattori:latest"
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
    RUST_LOG         = "laskugeneraattori=debug,tower_http=debug,axum::rejection=trace"
    RUST_LOG_STYLE   = "never"
    MAILGUN_URL      = "${module.mailgun.api_url_with_domain}/messages"
    MAILGUN_USER     = "api"
    MAILGUN_PASSWORD = var.mailgun_api_key
    MAILGUN_TO       = "Rahastonhoitaja <rahastonhoitaja@tietokilta.fi>"
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
  dns_resource_group_name         = var.dns_resource_group_name
  custom_domain_verification_id   = azurerm_linux_web_app.invoice_generator.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.invoice_generator.name
  app_service_resource_group_name = var.resource_group_name
  app_service_location            = var.resource_group_location
  app_service_default_hostname    = azurerm_linux_web_app.invoice_generator.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "tik-invoice-generator-cert-${terraform.workspace}"
}

