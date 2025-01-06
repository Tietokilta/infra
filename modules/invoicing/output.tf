output "fqdn" {
  value = local.fqdn
}
output "invoicing_app_id" {
  value = azurerm_linux_web_app.invoice_generator.id
}
