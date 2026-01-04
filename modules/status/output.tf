output "app_id" {
  value = azurerm_linux_web_app.status_app.id
}

output "managed_identity" {
  value = {
    principal_id = azurerm_linux_web_app.status_app.identity[0].principal_id
    tenant_id    = azurerm_linux_web_app.status_app.identity[0].tenant_id
  }
  description = "Managed identity of the status app for Key Vault access"
}
