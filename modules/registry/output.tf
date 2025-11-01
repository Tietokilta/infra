output "fqdn" {
  value = module.app_service_hostname.fqdn
}

output "registry_app_id" {
  value = azurerm_linux_web_app.registry.id
}
