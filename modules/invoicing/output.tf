output "fqdn" {
  value = module.app_service_hostname.fqdn
}
output "invoicing_app_id" {
  value = azurerm_linux_web_app.invoice_generator.id
}
