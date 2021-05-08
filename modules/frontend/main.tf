resource "azurerm_storage_account" "tikweb_sa" {
  name                      = "tikweb${var.env_name}sa"
  resource_group_name       = var.resource_group_name
  location                  = var.resource_group_location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  allow_blob_public_access  = true
  min_tls_version           = "TLS1_2"

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }
}
