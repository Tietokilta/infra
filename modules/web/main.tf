resource "azurerm_storage_account" "storage_account" {
  name                     = "tikwebstorage${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
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

resource "random_password" "revalidation_key" {
  length  = 32
  special = true
}

resource "random_password" "payload_secret" {
  length  = 32
  special = true
}

resource "random_password" "payload_password" {
  length  = 32
  special = false
}

resource "azurerm_linux_web_app" "web" {
  name                = "tikweb-web-${var.environment}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id
  site_config {
    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/web:latest"
    }

    http2_enabled = true
  }
  lifecycle {
    // image is deployed by web-repos GHA workflow
    ignore_changes = [
      site_config.0.application_stack.0.docker_image_name,
    ]
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
    NODE_ENV                          = "production"
    PUBLIC_ILMOMASIINA_URL            = var.public_ilmo_url
    NEXT_PUBLIC_ILMOMASIINA_URL       = var.public_ilmo_url
    NEXT_PUBLIC_LASKUGENERAATTORI_URL = var.public_laskugeneraattori_url
    WEBSITES_PORT                     = 3000
    PORT                              = 3000
    NEXT_REVALIDATION_KEY             = random_password.revalidation_key.result
    PUBLIC_LEGACY_URL                 = var.public_legacy_url
    PUBLIC_FRONTEND_URL               = "https://${module.tikweb_hostname.fqdn}"
    DIGITRANSIT_SUBSCRIPTION_KEY      = var.digitransit_subscription_key
    PAYLOAD_MONGO_CONNECTION_STRING   = var.mongo_connection_string
    PAYLOAD_SECRET                    = random_password.payload_secret.result
    PAYLOAD_REVALIDATION_KEY          = random_password.revalidation_key.result
    PAYLOAD_DEFAULT_USER_EMAIL        = "root@tietokilta.fi"
    PAYLOAD_DEFAULT_USER_PASSWORD     = random_password.payload_password.result
    AZURE_STORAGE_CONNECTION_STRING   = azurerm_storage_account.storage_account.primary_connection_string
    AZURE_STORAGE_ACCOUNT_BASEURL     = azurerm_storage_account.storage_account.primary_blob_endpoint
    AZURE_STORAGE_CONTAINER_NAME      = azurerm_storage_container.uploads_container.name
    GOOGLE_OAUTH_CLIENT_ID            = var.google_oauth_client_id
    GOOGLE_OAUTH_CLIENT_SECRET        = var.google_oauth_client_secret
    MAILGUN_SENDER                    = var.mailgun_sender
    MAILGUN_RECEIVER                  = var.mailgun_receiver
    MAILGUN_API_KEY                   = var.mailgun_api_key
    MAILGUN_DOMAIN                    = var.mailgun_domain
    MAILGUN_URL                       = var.mailgun_url
  }
}

module "tikweb_hostname" {
  source = "../app_service_hostname"

  subdomain                       = var.subdomain
  root_zone_name                  = var.root_zone_name
  dns_resource_group_name         = var.dns_resource_group_name
  custom_domain_verification_id   = azurerm_linux_web_app.web.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.web.name
  app_service_resource_group_name = var.resource_group_name
  app_service_location            = var.resource_group_location
  app_service_default_hostname    = azurerm_linux_web_app.web.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "tikweb-cert-${var.environment}"
}
