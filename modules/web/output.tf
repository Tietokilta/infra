output "managed_identity" {
  value = {
    principal_id = azurerm_linux_web_app.web.identity[0].principal_id
    tenant_id    = azurerm_linux_web_app.web.identity[0].tenant_id
  }
  description = "Managed identity of the web app for Key Vault access"
}

output "payload_password" {
  value     = random_password.payload_password.result
  sensitive = true
}
