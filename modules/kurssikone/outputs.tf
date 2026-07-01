output "backend_fqdn" {
  value = module.backend_hostname.fqdn
}

output "frontend_fqdn" {
  value = module.frontend_hostname.fqdn
}

output "backend_app_id" {
  value = azurerm_linux_web_app.kurssikone_backend.id
}

output "frontend_app_id" {
  value = azurerm_linux_web_app.kurssikone_frontend.id
}
