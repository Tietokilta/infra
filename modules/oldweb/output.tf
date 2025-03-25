output "fqdn" {
  value = local.fqdn
}
output "app_id" {
  value = azurerm_linux_web_app.oldweb_backend.id
}
