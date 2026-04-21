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
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_account_static_website" "histotik_static_webiste" {
  storage_account_id = azurerm_storage_account.histotik_storage_account.id
  index_document     = "index.html"
}

resource "azurerm_storage_container" "histotik_storage_container" {
  name                  = "$web"
  storage_account_id    = azurerm_storage_account.histotik_storage_account.id
  container_access_type = "blob"
}
