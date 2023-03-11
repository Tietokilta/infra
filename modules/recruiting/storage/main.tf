resource "azurerm_resource_group" "tikjob_rg" {
  name     = "tikjob-${var.env_name}-rg"
  location = var.resource_group_location
}

resource "random_password" "db_password" {
  length           = 30
  special          = true
  override_special = "_%@"
}

resource "azurerm_mysql_server" "tikjob_mysql" {
  name                = "tikjob-${var.env_name}-mysql-server"
  location            = azurerm_resource_group.tikjob_rg.location
  resource_group_name = azurerm_resource_group.tikjob_rg.name

  administrator_login          = var.ghost_db_username
  administrator_login_password = random_password.db_password.result

  sku_name   = "B_Gen5_1"
  storage_mb = 5120 #Max size in MB
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}

resource "azurerm_mysql_database" "tikjob_mysql_db" {
  name                = "tikjob_${var.env_name}_ghost"
  resource_group_name = azurerm_resource_group.tikjob_rg.name
  server_name         = azurerm_mysql_server.tikjob_mysql.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_mysql_flexible_server" "tikjob_mysql_new" {
  name                   = "tikjob-${var.env_name}-mysql-flexible"
  resource_group_name    = azurerm_resource_group.tikjob_rg.name
  location               = azurerm_resource_group.tikjob_rg.location
  administrator_login    = var.ghost_db_username
  administrator_password = random_password.db_password.result
  sku_name               = "B_Standard_B1s"
  version                = "8.0.21"
  zone                   = "2"
}

resource "azurerm_mysql_flexible_database" "tikjob_mysql_db_new" {
  name                = "tikjob_${var.env_name}_ghost"
  resource_group_name = azurerm_resource_group.tikjob_rg.name
  server_name         = azurerm_mysql_flexible_server.tikjob_mysql_new.name
  charset             = "utf8mb3"
  collation           = "utf8mb3_unicode_ci"
}

# Enable access from other Azure services (TODO: Switch to IP list)
resource "azurerm_mysql_firewall_rule" "tikjob_mysql_access" {
  name                = "tikjob-${var.env_name}-mysql-access"
  resource_group_name = azurerm_resource_group.tikjob_rg.name
  server_name         = azurerm_mysql_server.tikjob_mysql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Enable access from other Azure services (TODO: Switch to IP list)
resource "azurerm_mysql_flexible_server_firewall_rule" "tikjob_new_mysql_access" {
  name                = "tikjob-${var.env_name}-new-mysql-access"
  resource_group_name = azurerm_resource_group.tikjob_rg.name
  server_name         = azurerm_mysql_flexible_server.tikjob_mysql_new.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_storage_account" "tikjob_storage_account" {
  name                            = "tikjob${var.env_name}contentsa"
  resource_group_name             = azurerm_resource_group.tikjob_rg.name
  location                        = azurerm_resource_group.tikjob_rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_share" "tikjob_storage_share" {
  name                 = "ghost-content"
  storage_account_name = azurerm_storage_account.tikjob_storage_account.name
  quota                = 5 # Max size in GB
}
