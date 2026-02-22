output "storage_account_id" {
  description = "The ID of the histotik storage account."
  value       = azurerm_storage_account.histotik_storage_account.id
}

output "cdn_profile_id" {
  description = "The ID of the histotik CDN profile."
  value       = azurerm_cdn_profile.histotik_cdn_profile.id
}
