output "frontend_app_id" {
  value = azurerm_linux_web_app.frontend.id
}
output "strapi_app_id" {
  value = azurerm_linux_web_app.strapi.id
}

output "frontend_managed_identity" {
  value = {
    principal_id = azurerm_linux_web_app.frontend.identity[0].principal_id
    tenant_id    = azurerm_linux_web_app.frontend.identity[0].tenant_id
  }
  description = "Managed identity of the m0 frontend app for Key Vault access"
}

output "strapi_managed_identity" {
  value = {
    principal_id = azurerm_linux_web_app.strapi.identity[0].principal_id
    tenant_id    = azurerm_linux_web_app.strapi.identity[0].tenant_id
  }
  description = "Managed identity of the m0 strapi app for Key Vault access"
}
