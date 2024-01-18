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
