output "fqdn" {
  value = module.app_service_hostname.fqdn
}

output "app_id" {
  value = azurerm_linux_web_app.ufositsit.id
}

output "admin_password" {
  value     = random_password.admin_password.result
  sensitive = true
}
