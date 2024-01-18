resource "azurerm_storage_account" "tikweb_storage_account" {
  name                            = "tikwebstorage${terraform.workspace}"
  resource_group_name             = var.resource_group_name
  location                        = var.resource_group_location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
}


resource "azurerm_storage_container" "tikweb_media" {
  name                  = "media-${terraform.workspace}"
  storage_account_name  = azurerm_storage_account.tikweb_storage_account.name
  container_access_type = "private"
  depends_on            = [azurerm_storage_account.tikweb_storage_account]
}
