output "fqdn" {
  value = local.fqdn
}

output "web_app_id" {
  value = azurerm_linux_web_app.oldweb_backend.id
}
