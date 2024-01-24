// Storage

output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}
output "storage_connection_string" {
  value     = azurerm_storage_account.storage_account.primary_connection_string
  sensitive = true
}
output "container_name" {
  value = azurerm_storage_container.container.name
}
output "storage_account_base_url" {
  value = azurerm_storage_account.storage_account.primary_blob_endpoint
}
output "storage_access_key" {
  value     = azurerm_storage_account.storage_account.primary_access_key
  sensitive = true
}
