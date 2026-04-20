module "service_database" {
  source = "../service_database"

  db_name              = "running_challenge"
  postgres_server_id   = var.postgres_server_id
  postgres_server_fqdn = var.postgres_server_fqdn
}

resource "azurerm_linux_web_app" "running_challenge" {
  name                = "tik-running-challenge"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id

  site_config {
    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/running-challenge:latest"
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
    CLUB_ID       = var.club_id
    CLIENT_ID     = var.client_id
    CLIENT_SECRET = var.client_secret
    REFRESH_TOKEN = var.refresh_token
    PGHOST        = var.postgres_server_fqdn
    PGPORT        = 6432
    PGDATABASE    = module.service_database.db_name
    PGUSER        = module.service_database.db_user
    PGPASSWORD    = module.service_database.db_password
    PGSSLMODE     = "require"
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
  custom_domain_verification_id   = azurerm_linux_web_app.running_challenge.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.running_challenge.name
  app_service_resource_group_name = var.resource_group_name
  app_service_location            = var.resource_group_location
  app_service_default_hostname    = azurerm_linux_web_app.running_challenge.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "tik-running-challenge-cert"
}
