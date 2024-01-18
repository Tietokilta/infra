locals {
  payload_port = 3001
}
resource "random_password" "revalidation_key" {
  length  = 32
  special = true
}
resource "azurerm_linux_web_app" "frontend" {
  name                          = "tikweb-frontend-${terraform.workspace}"
  location                      = var.resource_group_location
  resource_group_name           = var.resource_group_name
  service_plan_id               = var.app_service_plan_id
  virtual_network_subnet_id     = var.public_subnet_id
  public_network_access_enabled = true
  site_config {
    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/web:latest"
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
    WEBSITES_PORT         = 3000
    PORT                  = 3000
    NEXT_REVALIDATION_KEY = random_password.revalidation_key.result
    SERVER_URL            = "http://${azurerm_linux_web_app.cms.default_hostname}:${local.payload_port}"
  }
}
resource "random_password" "payload_secret" {
  length  = 32
  special = true
}
resource "azurerm_linux_web_app" "cms" {
  name                          = "tikweb-cms-${terraform.workspace}"
  location                      = var.resource_group_location
  resource_group_name           = var.resource_group_name
  service_plan_id               = var.app_service_plan_id
  virtual_network_subnet_id     = var.private_subnet_id
  public_network_access_enabled = false
  site_config {

    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/cms:latest"
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
    PUBLIC_FRONTEND_URL             = "https://${local.fqdn}"
    PAYLOAD_MONGO_CONNECTION_STRING = var.mongo_connection_string
    PAYLOAD_SECRET                  = random_password.payload_secret.result
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
  origin {
    name      = "tikweb-frontend-${terraform.workspace}"
    host_name = azurerm_linux_web_app.frontend.default_hostname
  }

  global_delivery_rule {
    cache_expiration_action {
      behavior = "Override"
      duration = "10.00:00:00"
    }
  }

  delivery_rule {
    name  = "NextStaticAssets"
    order = 1

    request_uri_condition {
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

  # Deletion needs manual work. Hashicorp seems uninterested in fixing.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/11231
  depends_on = [
    azurerm_dns_cname_record.tikweb_cdn_cname_record
  ]
}
