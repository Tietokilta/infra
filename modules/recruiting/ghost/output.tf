output "fqdn" {
  value = module.tikjob_hostname.fqdn
}

output "managed_identity" {
  value = {
    principal_id = azurerm_linux_web_app.tikjob_ghost.identity[0].principal_id
    tenant_id    = azurerm_linux_web_app.tikjob_ghost.identity[0].tenant_id
  }
  description = "Managed identity of the tikjob ghost app for Key Vault access"
}
