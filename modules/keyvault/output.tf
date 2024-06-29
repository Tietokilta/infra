output "keyvault_id" {
  value = azurerm_key_vault.keyvault.id
}

output "secrets" {
  value = {
    for s in local.keyvault_secrets : s => data.azurerm_key_vault_secret.secret[s].value
  }
  sensitive = true
}
