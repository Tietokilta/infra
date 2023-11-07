terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "2.13.0-beta1"
    }
  }
}


resource "azurerm_resource_group" "tikweb_rg" {
  name     = "tikweb-${var.env_name}-rg"
  location = var.resource_group_location
}

resource "random_password" "db_password" {
  length           = 30
  special          = true
  override_special = "_%@"
}

# Shared Postgres server
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
  administrator_login_password = random_password.db_password.result
  version                      = "11"
  ssl_enforcement_enabled      = true
}

resource "azurerm_postgresql_flexible_server" "tikweb_pg_new" {
  name                         = "tikweb-${var.env_name}-pg-server-new"
  resource_group_name          = azurerm_resource_group.tikweb_rg.name
  location                     = azurerm_resource_group.tikweb_rg.location
  version                      = "15"
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
resource "azurerm_postgresql_firewall_rule" "tikweb_pg_internal_access" {
  name                = "tikweb-${var.env_name}-pg-internal-access"
  resource_group_name = azurerm_resource_group.tikweb_rg.name
  server_name         = azurerm_postgresql_server.tikweb_pg.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Shared App Service Plan
resource "azurerm_service_plan" "tikweb_plan" {
  name                = "tik-${var.env_name}-app-service-plan"
  location            = azurerm_resource_group.tikweb_rg.location
  resource_group_name = azurerm_resource_group.tikweb_rg.name

  os_type  = "Linux"
  sku_name = "B2"
}

resource "tls_private_key" "acme_account_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "acme_registration" "acme_reg" {
  account_key_pem = tls_private_key.acme_account_key.private_key_pem
  email_address   = "admin@tietokilta.fi"
}
