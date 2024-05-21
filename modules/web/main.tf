locals {
  payload_port = 3001
}
resource "azurerm_storage_account" "storage_account" {
  name                     = "tikwebstorage${terraform.workspace}"
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}


resource "azurerm_storage_container" "media_container" {
  name                  = "media-${terraform.workspace}"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"

}
resource "azurerm_storage_container" "documents_container" {
  name                  = "documents-${terraform.workspace}"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"

}
resource "random_password" "revalidation_key" {
  length  = 32
  special = true
}
resource "azurerm_linux_web_app" "web" {
  name                = "tikweb-web-${terraform.workspace}"
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
    NODE_ENVIRONMENT       = "production"
    PUBLIC_ILMOMASIINA_URL = var.public_ilmo_url
    WEBSITES_PORT          = 3000
    PORT                   = 3000
    NEXT_REVALIDATION_KEY  = random_password.revalidation_key.result
    PUBLIC_SERVER_URL      = "https://${azurerm_linux_web_app.cms.default_hostname}"
    PUBLIC_LEGACY_URL      = var.public_legacy_url
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
resource "azurerm_linux_web_app" "cms" {
  name                = "tikweb-cms-${terraform.workspace}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id
  https_only          = true
  site_config {

    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/cms:latest"
    }

    ip_restriction {
      action      = "Allow"
      headers     = []
      priority    = 100
      service_tag = "AzureCloud"
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
  app_settings = {
    NODE_ENVIRONMENT                       = "production"
    PUBLIC_FRONTEND_URL                    = "https://${local.fqdn}"
    PAYLOAD_MONGO_CONNECTION_STRING        = var.mongo_connection_string
    PAYLOAD_MONGO_DB_NAME                  = "cms"
    PAYLOAD_SECRET                         = random_password.payload_secret.result
    PAYLOAD_REVALIDATION_KEY               = random_password.revalidation_key.result
    PAYLOAD_DEFAULT_USER_EMAIL             = "root@tietokilta.fi"
    PAYLOAD_DEFAULT_USER_PASSWORD          = random_password.payload_password.result
    WEBSITES_PORT                          = local.payload_port
    PAYLOAD_PORT                           = local.payload_port
    AZURE_STORAGE_CONNECTION_STRING        = azurerm_storage_account.storage_account.primary_connection_string
    AZURE_STORAGE_ACCOUNT_BASEURL          = azurerm_storage_account.storage_account.primary_blob_endpoint
    AZURE_MEDIA_STORAGE_CONTAINER_NAME     = azurerm_storage_container.media_container.name
    AZURE_DOCUMENTS_STORAGE_CONTAINER_NAME = azurerm_storage_container.documents_container.name
    GOOGLE_OAUTH_CLIENT_ID                 = var.google_oauth_client_id
    GOOGLE_OAUTH_CLIENT_SECRET             = var.google_oauth_client_secret
  }
}


# CNAME record for www.
resource "azurerm_dns_cname_record" "www_cname" {
  name                = "www"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  record              = azurerm_linux_web_app.web.default_hostname
}

resource "azurerm_app_service_custom_hostname_binding" "tikweb_hostname_binding" {
  hostname            = local.fqdn
  app_service_name    = azurerm_linux_web_app.web.name
  resource_group_name = var.resource_group_name

  # Deletion may need manual work.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/11231
  # TODO: Add dependencies for creation
  depends_on = [
    azurerm_dns_a_record.tikweb_a,
    azurerm_dns_txt_record.tikweb_asuid
  ]
}
resource "azurerm_app_service_custom_hostname_binding" "www_hostname_binding" {
  hostname            = "www.${local.fqdn}"
  app_service_name    = azurerm_linux_web_app.web.name
  resource_group_name = var.resource_group_name
  depends_on = [
    azurerm_dns_cname_record.www_cname,
    azurerm_dns_txt_record.tikweb_asuid_www
  ]

}

resource "azurerm_app_service_managed_certificate" "www_cert" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.www_hostname_binding.id
}

resource "azurerm_app_service_certificate_binding" "www_cert_binding" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.www_hostname_binding.id
  certificate_id      = azurerm_app_service_managed_certificate.www_cert.id
  ssl_state           = "SniEnabled"
}

resource "random_password" "tikweb_cert_password" {
  length  = 48
  special = false
}

resource "acme_certificate" "tikweb_acme_cert" {
  account_key_pem          = var.acme_account_key
  common_name              = local.fqdn
  key_type                 = "2048" # RSA
  certificate_p12_password = random_password.tikweb_cert_password.result

  dns_challenge {
    provider = "azure"
    config = {
      AZURE_RESOURCE_GROUP = var.dns_resource_group_name
      AZURE_ZONE_NAME      = var.root_zone_name
    }
  }
}

resource "azurerm_app_service_certificate" "tikweb_cert" {
  name                = "tikweb-cert-${terraform.workspace}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  pfx_blob            = acme_certificate.tikweb_acme_cert.certificate_p12
  password            = acme_certificate.tikweb_acme_cert.certificate_p12_password
}

resource "azurerm_app_service_certificate_binding" "tikweb_cert_binding" {
  certificate_id      = azurerm_app_service_certificate.tikweb_cert.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.tikweb_hostname_binding.id
  ssl_state           = "SniEnabled"
}
