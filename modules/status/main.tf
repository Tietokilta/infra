terraform {
  required_providers {
    acme = {
      source = "vancluever/acme"
    }
  }
}

locals {
  fqdn = "${var.subdomain}.${var.root_zone_name}"
}

resource "azurerm_resource_group" "rg" {
  name     = "status-rg"
  location = var.location
}

# App Service (Linux Web App)
resource "azurerm_linux_web_app" "status_app" {
  name                = "tik-status-${terraform.workspace}"
  location            = var.location
  resource_group_name = var.app_service_plan_resource_group_name
  service_plan_id     = var.app_service_plan_id

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
  }
}


# A record for the web app
resource "azurerm_dns_a_record" "status_a" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = data.dns_a_record_set.status_dns_fetch.addrs
}

# Azure verification key
resource "azurerm_dns_txt_record" "status_asuid" {
  name                = "asuid.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.status_app.custom_domain_verification_id
  }
}


resource "azurerm_app_service_custom_hostname_binding" "status_hostname_binding" {
  hostname            = local.fqdn
  app_service_name    = azurerm_linux_web_app.status_app.name
  resource_group_name = var.app_service_plan_resource_group_name

  # Deletion may need manual work.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/11231
  # TODO: Add dependencies for creation
  depends_on = [
    azurerm_dns_a_record.status_a,
    azurerm_dns_txt_record.status_asuid
  ]
}

resource "random_password" "status_cert_password" {
  length  = 48
  special = false
}

resource "acme_certificate" "status_acme_cert" {
  account_key_pem          = var.acme_account_key
  common_name              = local.fqdn
  key_type                 = "2048" # RSA
  certificate_p12_password = random_password.status_cert_password.result

  dns_challenge {
    provider = "azuredns"
    config = {
      AZURE_RESOURCE_GROUP = var.dns_resource_group_name
      AZURE_ZONE_NAME      = var.root_zone_name
    }
  }
}

resource "azurerm_app_service_certificate" "status_cert" {
  name                = "tik-status-cert-${terraform.workspace}"
  resource_group_name = var.app_service_plan_resource_group_name
  location            = var.location
  pfx_blob            = acme_certificate.status_acme_cert.certificate_p12
  password            = acme_certificate.status_acme_cert.certificate_p12_password
}

resource "azurerm_app_service_certificate_binding" "status_cert_binding" {
  certificate_id      = azurerm_app_service_certificate.status_cert.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.status_hostname_binding.id
  ssl_state           = "SniEnabled"
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/14642#issuecomment-1084728235
# Currently, the azurerm provider doesn't give us the IP address, so we need to fetch it ourselves.
data "dns_a_record_set" "status_dns_fetch" {
  host = azurerm_linux_web_app.status_app.default_hostname
}
