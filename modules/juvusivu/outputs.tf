output "payload_password" {
  value     = random_password.payload_password.result
  sensitive = true
}
output "juvusivu_app_id" {
  value = azurerm_linux_web_app.juvusivu.id
}
