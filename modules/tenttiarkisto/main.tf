locals {
  db_name = "${var.env_name}_tentti_db"
}

resource "azurerm_resource_group" "tenttiarkisto_rg" {
  name     = "tenttiarkisto-${var.env_name}-rg"
  location = var.resource_group_location
}

resource "azurerm_postgresql_database" "tenttiarkisto_db" {
  name                = local.db_name
  resource_group_name = var.postgres_resource_group_name
  server_name         = var.postgres_server_name
  charset             = "UTF8"
  collation           = "fi-FI"
}

resource "azurerm_storage_account" "tenttiarkisto_storage_account" {
  name                      = "tenttiarkisto${var.env_name}sa"
  resource_group_name       = azurerm_resource_group.tenttiarkisto_rg.name
  location                  = azurerm_resource_group.tenttiarkisto_rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  allow_blob_public_access  = true
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
}

resource "azurerm_storage_container" "tenttiarkisto_storage_container" {
  name                  = "exams"
  storage_account_name  = azurerm_storage_account.tenttiarkisto_storage_account.name
  container_access_type = "blob"
}
