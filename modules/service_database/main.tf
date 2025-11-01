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


# Create a database role scoped to the this database
resource "postgresql_role" "db_user" {
  provider = postgresql.admin
  name     = "${var.db_name}_user"
  login    = true
  password = random_password.db_user_password.result
}

# Grant the role privileges only on this database
resource "postgresql_grant" "db_role" {
  provider    = postgresql.admin
  role        = postgresql_role.db_user.name
  database    = azurerm_postgresql_flexible_server_database.database.name
  privileges  = ["ALL"]
  object_type = "database"
}

# Grant access to existing tables
resource "postgresql_grant" "tables_access" {
  provider    = postgresql.admin
  database    = azurerm_postgresql_flexible_server_database.database.name
  schema      = "public"
  object_type = "table"
  objects     = ["*"]
  privileges  = ["ALL"]
  role        = postgresql_role.db_user.name
}

# Default access to future tables
resource "postgresql_default_privileges" "tables_access_future" {
  provider    = postgresql.admin
  database    = azurerm_postgresql_flexible_server_database.database.name
  schema      = "public"
  object_type = "table"
  privileges  = ["ALL"]
  role        = postgresql_role.db_user.name
  owner       = postgresql_role.db_user.name
}
