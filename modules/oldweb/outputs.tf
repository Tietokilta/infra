output "fqdn" {
  value = local.fqdn
}

output "web_app_id" {
  value = azurerm_linux_web_app.oldweb_backend.id
}

output "static_site_storage_account_id" {
  value = azurerm_storage_account.static_site.id
}
