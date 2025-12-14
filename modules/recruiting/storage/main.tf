resource "azurerm_resource_group" "tikjob_rg" {
  name     = "tikjob-${var.env_name}-rg"
  location = var.resource_group_location
}

resource "random_password" "db_password" {
  length           = 30
  special          = true
  override_special = "_%@"
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
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mysql_flexible_database" "tikjob_mysql_db_new" {
  name                = "tikjob_${var.env_name}_ghost"
  resource_group_name = azurerm_resource_group.tikjob_rg.name
  server_name         = azurerm_mysql_flexible_server.tikjob_mysql_new.name
  charset             = "utf8mb3"
  collation           = "utf8mb3_unicode_ci"
  lifecycle {
    prevent_destroy = true
  }
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
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_share" "tikjob_storage_share" {
  name               = "ghost-content"
  storage_account_id = azurerm_storage_account.tikjob_storage_account.id
  quota              = 5 # Max size in GB
}
