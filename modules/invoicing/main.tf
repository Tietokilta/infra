terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "2.19.0"
    }
  }
}

locals {
  fqdn = "${var.subdomain}.${var.root_zone_name}"
}

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
  lifecycle {
    // image is deployed by web-repos GHA workflow
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
    application_logs {
      file_system_level = "Information"
    }
  }
  https_only = true
  app_settings = {
    PORT             = 3000
    WEBSITES_PORT    = 3000
    EXPOSE           = 1
    RUST_LOG         = "laskugeneraattori=debug,tower_http=debug,axum::rejection=trace"
    MAILGUN_URL      = var.mailgun_url
    MAILGUN_USER     = var.mailgun_user
    MAILGUN_PASSWORD = var.mailgun_api_key
    MAILGUN_TO       = "Rahastonhoitaja <rahastonhoitaja@tietokilta.fi>"
    MAILGUN_FROM     = "noreply@laskutus.tietokilta.fi"
  }
}

resource "azurerm_app_service_custom_hostname_binding" "invoice_generator_hostname_binding" {
  hostname            = local.fqdn
  app_service_name    = azurerm_linux_web_app.invoice_generator.name
  resource_group_name = var.resource_group_name

  # Deletion may need manual work.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/11231
  # TODO: Add dependencies for creation
  depends_on = [
    azurerm_dns_a_record.invoice_generator_a,
    azurerm_dns_txt_record.invoice_generator_asuid
  ]
}

resource "random_password" "invoice_generator_cert_password" {
  length  = 48
  special = false
}

resource "acme_certificate" "invoice_generator_acme_cert" {
  account_key_pem          = var.acme_account_key
  common_name              = local.fqdn
  key_type                 = "2048" # RSA
  certificate_p12_password = random_password.invoice_generator_cert_password.result

  dns_challenge {
    provider = "azure"
    config = {
      AZURE_RESOURCE_GROUP = var.dns_resource_group_name
      AZURE_ZONE_NAME      = var.root_zone_name
    }
  }
}

resource "azurerm_app_service_certificate" "invoice_generator_cert" {
  name                = "tik-invoice-generator-cert-${terraform.workspace}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  pfx_blob            = acme_certificate.invoice_generator_acme_cert.certificate_p12
  password            = acme_certificate.invoice_generator_acme_cert.certificate_p12_password
}

resource "azurerm_app_service_certificate_binding" "invoice_generator_cert_binding" {
  certificate_id      = azurerm_app_service_certificate.invoice_generator_cert.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.invoice_generator_hostname_binding.id
  ssl_state           = "SniEnabled"
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/14642#issuecomment-1084728235
# Currently, the azurerm provider doesn't give us the IP address, so we need to fetch it ourselves.
data "dns_a_record_set" "invoice_generator_dns_fetch" {
  host = azurerm_linux_web_app.invoice_generator.default_hostname
}

