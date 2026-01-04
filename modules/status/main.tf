resource "azurerm_resource_group" "rg" {
  name     = "status-rg"
  location = var.location
}

resource "random_password" "guild-room-infoscreen-token" {
  length  = 32
  special = false
}

# App Service (Linux Web App)
resource "azurerm_linux_web_app" "status_app" {
  name                = "tik-status-${terraform.workspace}"
  location            = var.location
  resource_group_name = var.app_service_plan_resource_group_name
  service_plan_id     = var.app_service_plan_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    ftps_state = "Disabled"
    always_on  = false

    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "Tietokilta/tik-status:latest"
    }
  }

  lifecycle {
    // image is deployed by web-repos GHA workflow
    ignore_changes = [
      site_config.0.application_stack.0.docker_image_name,
    ]
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                       = "8080"
    TELEGRAM_TOKEN                      = var.telegram_token
    ALERT_CHANNEL_ID                    = var.telegram_channel_id
    INFOSCREEN_TOKEN                    = random_password.guild-room-infoscreen-token.result
  }
}


module "app_service_hostname" {
  source                          = "../app_service_hostname"
  subdomain                       = var.subdomain
  root_zone_name                  = var.root_zone_name
  dns_resource_group_name         = var.dns_resource_group_name
  custom_domain_verification_id   = azurerm_linux_web_app.status_app.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.status_app.name
  app_service_resource_group_name = var.app_service_plan_resource_group_name
  app_service_location            = var.location
  app_service_default_hostname    = azurerm_linux_web_app.status_app.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "tik-status-cert-${terraform.workspace}"
}
