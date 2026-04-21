output "storage_account_id" {
  description = "The ID of the histotik storage account."
  value       = azurerm_storage_account.histotik_storage_account.id
}
