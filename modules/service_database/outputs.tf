output "db_user" {
  value = postgresql_role.db_user.name
}

output "db_password" {
  value     = random_password.db_user_password.result
  sensitive = true
}

output "db_name" {
  value = azurerm_postgresql_flexible_server_database.database.name
}
