output "managed_identity" {
  value = {
    principal_id = azurerm_linux_web_app.ilmo_backend.identity[0].principal_id
    tenant_id    = azurerm_linux_web_app.ilmo_backend.identity[0].tenant_id
  }
  description = "Managed identity of the ilmo staging app for Key Vault access"
}
