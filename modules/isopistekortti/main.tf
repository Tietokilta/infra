locals {
  postgres_db_name = "isopistekortti_${var.environment}"
}

resource "random_password" "jwt_secret" {
  length  = 48
  special = false
}

resource "azurerm_postgresql_flexible_server_database" "isopistekortti_db" {
  name      = local.postgres_db_name
  server_id = var.postgres_server_id
  charset   = "utf8"
}

resource "azurerm_linux_web_app" "isopistekortti" {
  name                = "tik-isopistekortti-${var.environment}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id

  site_config {
    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/isopistekortti:latest"
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
    WEBSITES_PORT = 3000
    PORT          = 3000
    BIND_ADDRESS  = "0.0.0.0"
    JWT_SECRET    = random_password.jwt_secret.result
    NODE_ENV      = "production"
    DB_URL        = var.postgres_server_fqdn
    DB_USER       = var.postgres_admin_username
    DB_PASSWORD   = var.postgres_admin_password
    DB_DATABASE   = local.postgres_db_name
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
  custom_domain_verification_id   = azurerm_linux_web_app.isopistekortti.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.isopistekortti.name
  app_service_resource_group_name = var.resource_group_name
  app_service_location            = var.resource_group_location
  app_service_default_hostname    = azurerm_linux_web_app.isopistekortti.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "tik-isopistekortti-cert-${var.environment}"
}
