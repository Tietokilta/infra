// Mongo
output "mongo_connection_string" {
  value     = "${azurerm_cosmosdb_account.db_account.primary_mongodb_connection_string}/${azurerm_cosmosdb_mongo_database.db.name}"
  sensitive = true
}

// Storage

output "storage_account_name" {
  value = azurerm_storage_account.tikweb_storage_account.name
}
output "storage_connection_string" {
  value     = azurerm_storage_account.tikweb_storage_account.primary_connection_string
  sensitive = true
}
output "storage_container_name" {
  value = azurerm_storage_container.tikweb_media.name
}
output "storage_account_base_url" {
  value = azurerm_storage_account.tikweb_storage_account.primary_blob_endpoint
}
