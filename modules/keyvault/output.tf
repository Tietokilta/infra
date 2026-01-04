output "keyvault_id" {
  value = azurerm_key_vault.keyvault.id
}

output "keyvault_uri" {
  value = azurerm_key_vault.keyvault.vault_uri
}

output "secret_references" {
  value = {
    for s in var.keyvault_secrets : s => "@Microsoft.KeyVault(SecretUri=${data.azurerm_key_vault_secret.secret[s].versionless_id})"
  }
  description = "Key Vault references for use in App Service app settings"
}

output "secrets" {
  value = {
    for s in var.keyvault_secrets : s => data.azurerm_key_vault_secret.secret[s].value
  }
  sensitive   = true
  description = "Deprecated: Direct secret values. Use secret_references instead."
}
