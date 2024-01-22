locals {
  payload_port = 3001
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
  }
}
resource "random_password" "payload_secret" {
  length  = 32
  special = true
}
resource "random_password" "payload_password" {
  length  = 32
  special = true
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
    NODE_ENVIRONMENT                = "production"
    PUBLIC_FRONTEND_URL             = "https://${local.fqdn}"
    PAYLOAD_MONGO_CONNECTION_STRING = var.mongo_connection_string
    PAYLOAD_MONGO_DB_NAME           = "cms"
    PAYLOAD_SECRET                  = random_password.payload_secret.result
    PAYLOAD_REVALIDATION_KEY        = random_password.revalidation_key.result
    PAYLOAD_DEFAULT_USER_EMAIL      = "root@tietokilta.fi"
    PAYLOAD_DEFAULT_USER_PASSWORD   = random_password.payload_password.result
    WEBSITES_PORT                   = local.payload_port
    PAYLOAD_PORT                    = local.payload_port
    AZURE_STORAGE_CONNECTION_STRING = var.storage_connection_string
    AZURE_STORAGE_CONTAINER_NAME    = var.storage_container_name
    AZURE_STORAGE_ACCOUNT_BASEURL   = var.storage_account_base_url
    GOOGLE_OAUTH_CLIENT_ID          = var.google_oauth_client_id
    GOOGLE_OAUTH_CLIENT_SECRET      = var.google_oauth_client_secret
  }
}

resource "azurerm_cdn_profile" "cdn" {
  name                = "cdn-${terraform.workspace}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "next-cdn-endpoint" {
  name                = "next-cdn-endpoint-${terraform.workspace}"
  profile_name        = azurerm_cdn_profile.cdn.name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  is_http_allowed     = false
  is_https_allowed    = true
  # TODO: Add custom domain support
  querystring_caching_behaviour = "BypassCaching"
  origin {
    name      = "tikweb-web-${terraform.workspace}"
    host_name = azurerm_linux_web_app.web.default_hostname

  }
  origin_host_header = local.fqdn
  global_delivery_rule {
    cache_expiration_action {
      behavior = "Override"
      duration = "10.00:00:00"
    }
  }
  probe_path = "/next_api/health"
  delivery_rule {
    name  = "NextStaticAssets"
    order = 1
    url_path_condition {
      operator = "BeginsWith"
      match_values = [
        "/_next/static/"
      ]
    }
    cache_expiration_action {
      behavior = "Override"
      duration = "10.00:00:00"
    }
  }
}

resource "azurerm_cdn_endpoint_custom_domain" "tikweb_cdn_domain" {
  name            = "web-cdn-${terraform.workspace}-domain"
  cdn_endpoint_id = azurerm_cdn_endpoint.next-cdn-endpoint.id
  host_name       = "cdn.${var.subdomain}.${var.root_zone_name}"

  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
    tls_version      = "TLS12"
  }

  # Deletion may need manual work.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/11231
  # TODO: Add dependencies for creation
  depends_on = [azurerm_dns_cname_record.tikweb_cdn_cname_record]
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
