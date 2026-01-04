output "fqdn" {
  value = module.app_service_hostname.fqdn
}

output "registry_app_id" {
  value = azurerm_linux_web_app.registry.id
}

output "managed_identity" {
  value = {
    principal_id = azurerm_linux_web_app.registry.identity[0].principal_id
    tenant_id    = azurerm_linux_web_app.registry.identity[0].tenant_id
  }
  description = "Managed identity of the registry app for Key Vault access"
}
