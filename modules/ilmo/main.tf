terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "2.19.0"
    }
  }
}

locals {
  db_name = "${var.env_name}_ilmo_db"
  fqdn    = "${var.subdomain}.${var.root_zone_name}"
}

resource "azurerm_postgresql_flexible_server_database" "ilmo_db_new" {
  name      = local.db_name
  server_id = var.postgres_server_id
  charset   = "utf8"
}


resource "azurerm_linux_web_app" "ilmo_backend" {
  name                = "tik-ilmo-${var.env_name}-app"
  location            = var.tikweb_rg_location
  resource_group_name = var.tikweb_rg_name
  service_plan_id     = var.tikweb_app_plan_id

  https_only = true

  site_config {
    ftps_state = "Disabled"
    always_on  = true

    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/ilmomasiina:latest"
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
    DOCKER_REGISTRY_SERVER_URL = "https://ghcr.io"

    WEBSITES_PORT = 3000
    PORT          = 3000

    DB_DIALECT  = "postgres"
    DB_HOST     = var.postgres_server_fqdn
    DB_SSL      = true
    DB_DATABASE = local.db_name
    DB_USER     = "tietokilta"
    DB_PASSWORD = var.postgres_admin_password

    ADMIN_REGISTRATION_ALLOWED = false

    NEW_EDIT_TOKEN_SECRET = var.edit_token_secret
    FEATHERS_AUTH_SECRET  = var.auth_jwt_secret

    MAIL_FROM       = "noreply@${var.mailgun_domain}"
    MAILGUN_API_KEY = var.mailgun_api_key
    MAILGUN_DOMAIN  = var.mailgun_domain

    ALLOW_ORIGIN = "*"

    # Paths from tikweb-web
    BASE_URL          = var.website_url
    EVENT_DETAILS_URL = "${var.website_url}/{lang}/events/{slug}"
    EDIT_SIGNUP_URL   = "${var.website_url}/{lang}/signups/{id}/{editToken}"
    ADMIN_URL         = "${local.fqdn}/admin"

    ICAL_UID_DOMAIN   = "tietokilta.fi"

    BRANDING_ICAL_CALENDAR_NAME = "Tietokilta"
    BRANDING_MAIL_FOOTER_TEXT   = "Ilmomasiina - tietokilta.fi"
    BRANDING_MAIL_FOOTER_LINK   = "${var.website_url}/fi/events"
  }

  lifecycle {
    ignore_changes = [
      site_config.0.application_stack, # deployments are made outside of Terraform
    ]
  }
}


resource "azurerm_app_service_custom_hostname_binding" "ilmo_hostname_binding" {
  hostname            = local.fqdn
  app_service_name    = azurerm_linux_web_app.ilmo_backend.name
  resource_group_name = var.resource_group_name

  # Deletion may need manual work.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/11231
  # TODO: Add dependencies for creation
  depends_on = [
    azurerm_dns_a_record.ilmo_a,
    azurerm_dns_txt_record.ilmo_asuid
  ]
}
resource "random_password" "ilmo_cert_password" {
  length  = 48
  special = false
}

resource "acme_certificate" "ilmo_acme_cert" {
  account_key_pem          = var.acme_account_key
  common_name              = local.fqdn
  key_type                 = "2048" # RSA
  certificate_p12_password = random_password.ilmo_cert_password.result

  dns_challenge {
    provider = "azure"
    config = {
      AZURE_RESOURCE_GROUP = var.dns_resource_group_name
      AZURE_ZONE_NAME      = var.root_zone_name
    }
  }
}

resource "azurerm_app_service_certificate" "ilmo_cert" {
  name                = "tik-ilmo-cert-${terraform.workspace}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  pfx_blob            = acme_certificate.ilmo_acme_cert.certificate_p12
  password            = acme_certificate.ilmo_acme_cert.certificate_p12_password
}

resource "azurerm_app_service_certificate_binding" "ilmo_cert_binding" {
  certificate_id      = azurerm_app_service_certificate.ilmo_cert.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.ilmo_hostname_binding.id
  ssl_state           = "SniEnabled"
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/14642#issuecomment-1084728235
# Currently, the azurerm provider doesn't give us the IP address, so we need to fetch it ourselves.
data "dns_a_record_set" "ilmo_dns_fetch" {
  host = azurerm_linux_web_app.ilmo_backend.default_hostname
}
