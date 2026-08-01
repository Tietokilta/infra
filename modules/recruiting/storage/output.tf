output "resource_group_name" {
  value = azurerm_resource_group.tikjob_rg.name
}

output "resource_group_location" {
  value = azurerm_resource_group.tikjob_rg.location
}

// MySQL

output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.tikjob_mysql_new.fqdn
}

output "mysql_username" {
  value = azurerm_mysql_flexible_server.tikjob_mysql_new.administrator_login
}

output "mysql_password" {
  value     = azurerm_mysql_flexible_server.tikjob_mysql_new.administrator_password
  sensitive = true
}

// Storage

output "storage_account_name" {
  value = azurerm_storage_account.tikjob_storage_account.name
}

output "storage_account_key" {
  value     = azurerm_storage_account.tikjob_storage_account.primary_access_key
  sensitive = true
}

output "storage_share_name" {
  value = azurerm_storage_share.tikjob_storage_share.name
}

output "mysql_db_name" {
  value = azurerm_mysql_flexible_database.tikjob_mysql_db_new.name
}
