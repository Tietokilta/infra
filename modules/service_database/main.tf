# Create postgres database
resource "azurerm_postgresql_flexible_server_database" "database" {
  name      = var.db_name
  server_id = var.postgres_server_id
  charset   = "utf8"
}

# Generate a password for the application database user that will only have access to this DB
resource "random_password" "db_user_password" {
  length           = 40
  override_special = "@-"
}


# Create a database role scoped to the oldweb database
resource "postgresql_role" "db_user" {
  provider = postgresql.admin
  name     = "${var.db_name}_user"
  login    = true
  password = random_password.db_user_password.result
}

# Grant the role privileges only on the oldweb database
resource "postgresql_grant" "db_role" {
  provider    = postgresql.admin
  role        = postgresql_role.db_user.name
  database    = azurerm_postgresql_flexible_server_database.database.name
  privileges  = ["ALL"]
  object_type = "database"
}
