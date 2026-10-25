locals {
  db_name = "${var.environment}_oldweb_db"
}

resource "azurerm_resource_group" "rg" {
  name     = "oldweb-${var.environment}-rg"
  location = var.location
}

# The old app's database and attachments, kept until their data is archived or deleted
module "service_database" {
  source = "../service_database"

  db_name              = local.db_name
  postgres_server_id   = var.postgres_server_id
  postgres_server_fqdn = var.postgres_server_fqdn
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
  lifecycle {
    prevent_destroy = true
  }
}

# File share
resource "azurerm_storage_share" "file_share" {
  name               = "oldweb-data"
  storage_account_id = azurerm_storage_account.storage_account.id
  quota              = 2 # GB
}
