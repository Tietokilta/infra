locals {
  db_name = "${var.env_name}_oldweb_db"
  fqdn    = "${var.subdomain}.${var.root_zone_name}"
}

resource "azurerm_resource_group" "rg" {
  name     = "oldweb-${var.env_name}-rg"
  location = var.location
}

# Create postgres database
resource "azurerm_postgresql_flexible_server_database" "oldweb_db" {
  name      = local.db_name
  server_id = var.postgres_server_id
  charset   = "utf8"
}

# Storage account
resource "azurerm_storage_account" "storage_account" {
  name                     = "oldwebstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Zone redundant https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy
  account_kind             = "StorageV2"
  access_tier              = "Hot"
}

# File share
resource "azurerm_storage_share" "file_share" {
  name                 = "oldweb-data"
  storage_account_name = azurerm_storage_account.storage_account.name
  quota                = 2 # GB
}

resource "azurerm_container_registry" "acr" {
  name                = "oldwebContainerRegistry"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
}
