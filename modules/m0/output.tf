output "frontend_app_id" {
  value = azurerm_linux_web_app.frontend.id
}
output "strapi_app_id" {
  value = azurerm_linux_web_app.strapi.id
}
