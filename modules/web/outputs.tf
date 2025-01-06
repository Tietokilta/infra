output "fqdn" {
  value = local.fqdn
}
output "payload_password" {
  value     = random_password.payload_password.result
  sensitive = true
}
output "web_app_id" {
  value = azurerm_linux_web_app.web.id
}
output "cms_app_id" {
  value = azurerm_linux_web_app.cms.id
}
