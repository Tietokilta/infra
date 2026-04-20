terraform {
  required_providers {
    acme = {
      source = "vancluever/acme"
    }
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
  }
}


resource "azurerm_resource_group" "tikweb_rg" {
  name     = "tikweb-${var.env_name}-rg"
  location = var.resource_group_location
}

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "_%@"
}

# Shared Postgres
resource "azurerm_postgresql_flexible_server" "tikweb_pg_new" {
  name                         = "tikweb-${var.env_name}-pg-server-new"
  resource_group_name          = azurerm_resource_group.tikweb_rg.name
  location                     = azurerm_resource_group.tikweb_rg.location
  version                      = "16"
  administrator_login          = "tietokilta"
  administrator_password       = random_password.db_password.result
  storage_mb                   = 32768
  sku_name                     = "B_Standard_B1ms"
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = false
  zone                         = "2"
}
# Enable access from other Azure services
resource "azurerm_postgresql_flexible_server_firewall_rule" "tikweb_pg_new_firewall" {
  name             = "tikweb-${var.env_name}-pg-new"
  server_id        = azurerm_postgresql_flexible_server.tikweb_pg_new.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Built-in PgBouncer (listens on port 6432). Multiplexes client connections
# onto the server's small max_connections pool so idle/zombie client sessions
# don't exhaust it.
resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_enabled" {
  name      = "pgbouncer.enabled"
  server_id = azurerm_postgresql_flexible_server.tikweb_pg_new.id
  value     = "true"
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_pool_mode" {
  name      = "pgbouncer.pool_mode"
  server_id = azurerm_postgresql_flexible_server.tikweb_pg_new.id
  value     = "TRANSACTION"
}

# B_Standard_B1ms has max_connections=50. With ~8 service DBs, keep
# default_pool_size small so total server-side conns stay under the cap.
resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_default_pool_size" {
  name      = "pgbouncer.default_pool_size"
  server_id = azurerm_postgresql_flexible_server.tikweb_pg_new.id
  value     = "5"
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_max_client_conn" {
  name      = "pgbouncer.max_client_conn"
  server_id = azurerm_postgresql_flexible_server.tikweb_pg_new.id
  value     = "200"
}

# Accept startup params that ORMs (Sequelize, Django) routinely set but that
# pgbouncer can't forward in transaction mode.
resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_ignore_startup_parameters" {
  name      = "pgbouncer.ignore_startup_parameters"
  server_id = azurerm_postgresql_flexible_server.tikweb_pg_new.id
  value     = "extra_float_digits,search_path"
}
# Shared App Service Plan
resource "azurerm_service_plan" "tikweb_plan" {
  name                = "tik-${var.env_name}-app-service-plan"
  location            = azurerm_resource_group.tikweb_rg.location
  resource_group_name = azurerm_resource_group.tikweb_rg.name

  os_type  = "Linux"
  sku_name = "P0v3"
}

resource "random_password" "backup_user_password" {
  length           = 32
  special          = true
  override_special = "_%@"
}

resource "postgresql_role" "backup_user" {
  name     = "backup"
  login    = true
  password = random_password.backup_user_password.result
  roles    = ["pg_read_all_data"]
}

resource "tls_private_key" "acme_account_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "acme_registration" "acme_reg" {
  account_key_pem = tls_private_key.acme_account_key.private_key_pem
  email_address   = "admin@tietokilta.fi"
}
