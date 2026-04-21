output "client_id" {
  description = "Client ID for the backup service principal."
  value       = azuread_application_registration.backup_storage.client_id
}

output "client_secret" {
  description = "Client secret for the backup service principal."
  value       = azuread_application_password.backup_storage.value
  sensitive   = true
}

output "tenant_id" {
  description = "Tenant ID for the backup service principal."
  value       = data.azurerm_client_config.current.tenant_id
}
