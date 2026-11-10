output "fqdn" {
  value = module.app_service_hostname.fqdn
}
output "pakuvaraus_app_id" {
  value = azurerm_linux_web_app.pakuvaraus.id
}
