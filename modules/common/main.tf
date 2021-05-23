resource "azurerm_resource_group" "tikweb_rg" {
  name     = "tikweb-${var.env_name}-rg"
  location = "northeurope"
}

resource "azurerm_postgresql_server" "tikweb_pg" {
  name                = "tikweb-${var.env_name}-pg-server"
  location            = azurerm_resource_group.tikweb_rg.location
  resource_group_name = azurerm_resource_group.tikweb_rg.name

  sku_name = "B_Gen5_1"

  storage_mb                   = 10240 # 10 GB
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = false

  administrator_login          = "tietokilta"
  administrator_login_password = var.postgres_admin_password
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
