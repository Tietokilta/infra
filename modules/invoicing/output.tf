output "fqdn" {
  value = module.app_service_hostname.fqdn
}
output "invoicing_app_id" {
  value = azurerm_linux_web_app.invoice_generator.id
}
output "managed_identity" {
  value = {
    principal_id = azurerm_linux_web_app.invoice_generator.identity[0].principal_id
    tenant_id    = azurerm_linux_web_app.invoice_generator.identity[0].tenant_id
  }
  description = "Managed identity of the invoice generator app for Key Vault access"
}
