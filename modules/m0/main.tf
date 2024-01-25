locals {
  fqdn    = "muistinnollaus.fi"
  db_name = "m0_${terraform.workspace}"
}

resource "azurerm_postgresql_flexible_server_database" "m0_db" {
  name      = local.db_name
  server_id = var.postgres_server_id
  charset   = "utf8"
}


resource "azurerm_linux_web_app" "frontend" {
  name                = "m0-frontend-${terraform.workspace}"
  location            = var.resource_group_location
  resource_group_name = var.web_resource_group_name
  service_plan_id     = var.app_service_plan_id
  site_config {
    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/m0-frontend:latest"
    }

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
    # Colors: Choose from https://tailwindcss.com/docs/customizing-colors
    PRIMARY_COLOR   = "purple"
    SECONDARY_COLOR = "neutral"


    PAYTRAIL_MERCHANT_ID = var.muistinnollaus_paytrail_merchant_id
    PAYTRAIL_SECRET_KEY  = var.muistinnollaus_paytrail_secret_key
    CALLBACK_URL         = "https://${local.fqdn}/api/verifyPaymentCallback"
    # Web auth
    STRAPI_TOKEN   = var.strapi_token
    STRAPI_URL     = "https://${azurerm_linux_web_app.strapi.default_hostname}"
    STRAPI_API_URL = "https://${azurerm_linux_web_app.strapi.default_hostname}"

  }
}
module "storage" {
  source                  = "../storage_container"
  container_name          = "m0-${terraform.workspace}"
  storage_account_name    = "m0${terraform.workspace}"
  resource_group_name     = var.web_resource_group_name
  resource_group_location = var.resource_group_location
  container_access_type   = "blob"
}
resource "azurerm_linux_web_app" "strapi" {
  name                = "m0-backend-${terraform.workspace}"
  location            = var.resource_group_location
  resource_group_name = var.web_resource_group_name
  service_plan_id     = var.app_service_plan_id
  https_only          = true
  site_config {

    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/m0-strapi:latest"
    }
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
  app_settings = {
    NODE_ENVIRONMENT       = "production"
    DATABASE_USERNAME      = "tietokilta"
    DATABASE_PASSWORD      = var.postgres_admin_password
    DATABASE_HOST          = var.postgres_server_fqdn
    DATABASE_SSL           = true
    DATABASE_NAME          = local.db_name
    SMTP_USER              = var.smtp_email
    SMTP_PASSWORD          = var.smtp_password
    SMTP_HOST              = "smtp.eu.mailgun.org"
    SMTP_TLS               = true
    APP_KEYS               = "${random_string.app_keys_1.result},${random_string.app_keys_2.result},${random_string.app_keys_3.result}"
    API_TOKEN_SALT         = random_string.api_token_salt.result
    ADMIN_JWT_SECRET       = random_string.admin_jwt_secret.result
    JWT_SECRET             = random_string.jwt_secret.result
    TRANSFER_TOKEN_SALT    = random_string.transfer_token_salt.result
    STORAGE_ACCOUNT        = module.storage.storage_account_name
    STORAGE_ACCOUNT_KEY    = module.storage.storage_access_key
    STORAGE_URL            = module.storage.storage_account_base_url
    STORAGE_CONTAINER_NAME = module.storage.container_name
  }
}


resource "azurerm_app_service_custom_hostname_binding" "m0_hostname_binding" {
  hostname            = local.fqdn
  app_service_name    = azurerm_linux_web_app.frontend.name
  resource_group_name = var.web_resource_group_name

  # Deletion may need manual work.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/11231
  # TODO: Add dependencies for creation
  depends_on = [
    azurerm_dns_a_record.m0_a,
    azurerm_dns_txt_record.m0_asuid
  ]
}
resource "random_password" "m0_cert_password" {
  length  = 48
  special = false
}

resource "acme_certificate" "m0_acme_cert" {
  account_key_pem          = var.acme_account_key
  common_name              = local.fqdn
  key_type                 = "2048" # RSA
  certificate_p12_password = random_password.m0_cert_password.result

  dns_challenge {
    provider = "azure"
    config = {
      AZURE_RESOURCE_GROUP = azurerm_resource_group.dns_rg.name
      AZURE_ZONE_NAME      = azurerm_dns_zone.m0_zone.name
    }
  }
}

resource "azurerm_app_service_certificate" "m0_cert" {
  name                = "m0-cert-${terraform.workspace}"
  resource_group_name = var.web_resource_group_name
  location            = var.resource_group_location
  pfx_blob            = acme_certificate.m0_acme_cert.certificate_p12
  password            = acme_certificate.m0_acme_cert.certificate_p12_password
}

resource "azurerm_app_service_certificate_binding" "m0_cert_binding" {
  certificate_id      = azurerm_app_service_certificate.m0_cert.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.m0_hostname_binding.id
  ssl_state           = "SniEnabled"
}
