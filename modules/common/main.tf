terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "2.19.0"
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

# Shared Postgres
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
resource "azurerm_postgresql_flexible_server_firewall_rule" "tikweb_pg_new_firewall" {
  name             = "tikweb-${var.env_name}-pg-new"
  server_id        = azurerm_postgresql_flexible_server.tikweb_pg_new.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
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
