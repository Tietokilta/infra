locals {
  db_name = "${var.environment}_kurssikone_db"
}

module "service_database" {
  source = "../service_database"

  db_name              = local.db_name
  postgres_server_id   = var.postgres_server_id
  postgres_server_fqdn = var.postgres_server_fqdn
}

# Backend API (api.kurssikone.com)
resource "azurerm_linux_web_app" "kurssikone_backend" {
  name                = "kurssikone-api-${var.environment}-app"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id

  https_only = true

  site_config {
    ftps_state = "Disabled"
    always_on  = true

    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/kurssikone-backend:latest"
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
    WEBSITES_PORT = 3001
    PORT          = 3001
    NODE_ENV      = "production"

    POSTGRES_HOST     = var.postgres_server_fqdn
    POSTGRES_PORT     = 5432
    POSTGRES_DB       = module.service_database.db_name
    POSTGRES_USER     = module.service_database.db_user
    POSTGRES_PASSWORD = module.service_database.db_password

    SISU_COURSE_API_KEY = var.sisu_course_api_key
    ADMIN_SECRET        = var.admin_secret
  }

  lifecycle {
    ignore_changes = [
      site_config.0.application_stack,
    ]
  }
}

# Frontend (kurssikone.com)
resource "azurerm_linux_web_app" "kurssikone_frontend" {
  name                = "kurssikone-web-${var.environment}-app"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id

  https_only = true

  site_config {
    ftps_state = "Disabled"
    always_on  = true

    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/kurssikone-web:latest"
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
    WEBSITES_PORT = 80
  }

  lifecycle {
    ignore_changes = [
      site_config.0.application_stack,
    ]
  }
}

# DNS + SSL for backend (api.kurssikone.com)
module "backend_hostname" {
  source = "../app_service_hostname"

  subdomain                       = "api"
  root_zone_name                  = var.root_zone_name
  custom_domain_verification_id   = azurerm_linux_web_app.kurssikone_backend.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.kurssikone_backend.name
  app_service_resource_group_name = var.resource_group_name
  app_service_location            = var.resource_group_location
  app_service_default_hostname    = azurerm_linux_web_app.kurssikone_backend.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "kurssikone-api-cert"
  cloudflare_zone_id              = var.cloudflare_zone_id
  cloudflare_api_token            = var.cloudflare_api_token
}

# DNS + SSL for frontend (kurssikone.com)
module "frontend_hostname" {
  source = "../app_service_hostname"

  subdomain                       = "@"
  root_zone_name                  = var.root_zone_name
  custom_domain_verification_id   = azurerm_linux_web_app.kurssikone_frontend.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.kurssikone_frontend.name
  app_service_resource_group_name = var.resource_group_name
  app_service_location            = var.resource_group_location
  app_service_default_hostname    = azurerm_linux_web_app.kurssikone_frontend.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "kurssikone-cert"
  cloudflare_zone_id              = var.cloudflare_zone_id
  cloudflare_api_token            = var.cloudflare_api_token
}
