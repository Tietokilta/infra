output "fqdn" {
  value = local.fqdn
}

output "static_site_storage_account_id" {
  value = azurerm_storage_account.static_site.id
}
