output "fqdn" {
  value = module.app_service_hostname.fqdn
}

output "app_id" {
  value = azurerm_linux_web_app.isopistekortti.id
}
