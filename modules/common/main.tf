locals {
  pg_server_name = "tikweb-${var.env_name}-pg-server"
}

resource "azurerm_resource_group" "tikweb_rg" {
  name     = "tikweb-${var.env_name}-rg"
  location = "northeurope"
}

resource "random_password" "db_password" {
  length           = 30
  special          = true
  override_special = "_%@"
}

# Shared Postgres server
resource "azurerm_postgresql_server" "tikweb_pg" {
  name                = local.pg_server_name
  location            = azurerm_resource_group.tikweb_rg.location
  resource_group_name = azurerm_resource_group.tikweb_rg.name

  sku_name = "B_Gen5_1"

  storage_mb                   = 10240 # 10 GB
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = false

  administrator_login          = "tietokilta"
  administrator_login_password = random_password.db_password.result
  version                      = "11"
  ssl_enforcement_enabled      = true
}

# Enable access from other Azure services
resource "azurerm_postgresql_firewall_rule" "tikweb_pg_internal_access" {
  name                = "tikweb-${var.env_name}-pg-internal-access"
  resource_group_name = azurerm_resource_group.tikweb_rg.name
  server_name         = azurerm_postgresql_server.tikweb_pg.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Shared App Service Plan for auxiliary services
resource "azurerm_app_service_plan" "aux_plan" {
  name                = "tik-aux-${var.env_name}-plan"
  location            = azurerm_resource_group.tikweb_rg.location
  resource_group_name = azurerm_resource_group.tikweb_rg.name

  kind     = "linux"
  reserved = true # Needs to be true for linux

  sku {
    tier = "Basic"
    size = "B1"
  }
}
