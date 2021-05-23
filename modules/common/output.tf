output "resource_group_name" {
  value = azurerm_resource_group.tikweb_rg.name
}

output "resource_group_location" {
  value = azurerm_resource_group.tikweb_rg.location
}

output "postgres_server_name" {
  value = azurerm_postgresql_server.tikweb_pg.name
}

output "postgres_server_fqdn" {
  value = azurerm_postgresql_server.tikweb_pg.fqdn
}

output "logs_sa_name" {
  value = azurerm_storage_account.logs_storage.name
}

output "logs_sa_connection_string" {
  value = azurerm_storage_account.logs_storage.primary_connection_string
}

output "logs_sa_blob_endpoint" {
  value = azurerm_storage_account.logs_storage.primary_connection_string
}
