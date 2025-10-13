locals {
  db_name = "${var.environment}_juvusivu_db"
}

resource "azurerm_resource_group" "rg" {
  name     = "juvusivu-${var.environment}-rg"
  location = var.location
}

# Create postgres database
resource "azurerm_postgresql_flexible_server_database" "juvusivu_db" {
  name      = local.db_name
  server_id = var.postgres_server_id
  charset   = "utf8"
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "juvusivustorage${var.environment}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}


resource "azurerm_storage_container" "uploads_container" {
  name                  = "uploads-${var.environment}"
  storage_account_id    = azurerm_storage_account.storage_account.id
  container_access_type = "private"
  lifecycle {
    prevent_destroy = true
  }
}

resource "random_password" "payload_secret" {
  length  = 32
  special = true
}

resource "random_password" "payload_password" {
  length  = 32
  special = false
}

resource "azurerm_linux_web_app" "juvusivu" {
  name                = "tik-juvusivu-${var.environment}"
  location            = var.app_service_plan_location
  resource_group_name = var.app_service_plan_resource_group_name
  service_plan_id     = var.app_service_plan_id
  site_config {
    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/juvusivu:latest"
    }

    http2_enabled = true
  }
  lifecycle {
    // image is deployed by juvusivu-repos GHA workflow
    ignore_changes = [
      site_config.0.application_stack.0.docker_image_name,
    ]
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

    PAYLOAD_SECRET                  = random_password.payload_secret.result
    PAYLOAD_DEFAULT_USER_EMAIL      = "root@tietokilta.fi"
    PAYLOAD_DEFAULT_USER_PASSWORD   = random_password.payload_password.result
    AZURE_STORAGE_CONNECTION_STRING = azurerm_storage_account.storage_account.primary_connection_string
    AZURE_STORAGE_ACCOUNT_BASEURL   = azurerm_storage_account.storage_account.primary_blob_endpoint
    AZURE_STORAGE_CONTAINER_NAME    = azurerm_storage_container.uploads_container.name

    DB_USER     = "tietokilta"
    DB_PASSWORD = var.postgres_admin_password
    DB_HOST     = var.postgres_server_fqdn
    DB_NAME     = local.db_name
    DB_PORT     = 5432

    PRIMARY_DOMAIN = var.root_zone_name // For m0 redirect
  }
}

module "juvusivu_hostname" {
  source = "../app_service_hostname"

  subdomain                       = "@"
  dns_resource_group_name         = var.dns_resource_group_name
  custom_domain_verification_id   = azurerm_linux_web_app.juvusivu.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.juvusivu.name
  app_service_resource_group_name = var.app_service_plan_resource_group_name
  app_service_location            = var.app_service_plan_location
  app_service_default_hostname    = azurerm_linux_web_app.juvusivu.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "juvusivu-cert"
  root_zone_name                  = var.root_zone_name
}

module "juvusivu_m0_hostname" {
  source = "../app_service_hostname"

  subdomain                       = "@"
  dns_resource_group_name         = var.m0_dns_resource_group_name
  custom_domain_verification_id   = azurerm_linux_web_app.juvusivu.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.juvusivu.name
  app_service_resource_group_name = var.app_service_plan_resource_group_name
  app_service_location            = var.app_service_plan_location
  app_service_default_hostname    = azurerm_linux_web_app.juvusivu.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "juvu-m0-cert"
  root_zone_name                  = var.m0_dns_zone_name
}
