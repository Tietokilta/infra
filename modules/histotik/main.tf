locals {
  fqdn = "${var.subdomain}.${var.root_zone_name}"
}

resource "azurerm_resource_group" "histotik_rg" {
  name     = "histotik-${var.env_name}-rg"
  location = var.resource_group_location
}

resource "azurerm_storage_account" "histotik_storage_account" {
  name                            = "histotik${var.env_name}sa"
  resource_group_name             = azurerm_resource_group.histotik_rg.name
  location                        = azurerm_resource_group.histotik_rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = true
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  static_website {
    index_document = "index.html"
  }
}

resource "azurerm_storage_container" "histotik_storage_container" {
  name                  = "$web"
  storage_account_name  = azurerm_storage_account.histotik_storage_account.name
  container_access_type = "blob"
}

resource "azurerm_cdn_profile" "histotik_cdn_profile" {
  name                = "histotik-${var.env_name}-cdn"
  resource_group_name = azurerm_resource_group.histotik_rg.name
  location            = azurerm_resource_group.histotik_rg.location
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "histotik_cdn_endpoint" {
  name                = "histotik-${var.env_name}"
  resource_group_name = azurerm_resource_group.histotik_rg.name
  location            = azurerm_resource_group.histotik_rg.location
  profile_name        = azurerm_cdn_profile.histotik_cdn_profile.name
  origin_host_header  = azurerm_storage_account.histotik_storage_account.primary_web_host

  origin {
    name      = "storage"
    host_name = azurerm_storage_account.histotik_storage_account.primary_web_host
  }

  delivery_rule {
    name  = "httpsredirect"
    order = 1

    request_scheme_condition {
      match_values = ["HTTP"]
    }
    url_redirect_action {
      redirect_type = "Found"
      protocol      = "Https"
    }
  }
}

resource "azurerm_cdn_endpoint_custom_domain" "histotik_cdn_domain" {
  name            = "histotik-${var.env_name}-domain"
  cdn_endpoint_id = azurerm_cdn_endpoint.histotik_cdn_endpoint.id
  host_name       = local.fqdn

  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
    tls_version      = "TLS12"
  }

  # Deletion needs manual work. Hashicorp seems uninterested in fixing.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/11231
  depends_on = [
    azurerm_dns_cname_record.histotik_cname_record
  ]
}
