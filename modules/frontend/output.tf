output "storage_account_name" {
  value = azurerm_storage_account.tikweb_sa.name
}

output "storage_account_key" {
  value     = azurerm_storage_account.tikweb_sa.primary_access_key
  sensitive = true
}

output "uploads_container_name" {
  value = azurerm_storage_container.tikweb_uploads.name
}
