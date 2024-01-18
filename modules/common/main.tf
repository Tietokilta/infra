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

resource "azurerm_virtual_network" "tiknet" {
  name                = "tiknet-${terraform.workspace}"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.tikweb_rg.location
  resource_group_name = azurerm_resource_group.tikweb_rg.name
}
resource "azurerm_subnet" "web-public-subnet" {
  name                 = "web-public-subnet-${terraform.workspace}"
  resource_group_name  = azurerm_resource_group.tikweb_rg.name
  virtual_network_name = azurerm_virtual_network.tiknet.name
  address_prefixes     = ["10.1.1.0/24"]
}
resource "azurerm_subnet" "web-private-subnet" {
  name                 = "web-private-subnet-${terraform.workspace}"
  resource_group_name  = azurerm_resource_group.tikweb_rg.name
  virtual_network_name = azurerm_virtual_network.tiknet.name
  address_prefixes     = ["10.1.2.0/24"]
}
resource "azurerm_network_security_group" "public_nsg" {
  name                = "public-nsg-${terraform.workspace}"
  location            = azurerm_resource_group.tikweb_rg.location
  resource_group_name = azurerm_resource_group.tikweb_rg.name
  security_rule {
    name                       = "AllowHTTPHTTPSInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowToPrivateSubnet"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.web-private-subnet.address_prefixes[0]
  }
  security_rule {
    name                       = "AllowInternetOutbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}
resource "azurerm_network_security_group" "private_nsg" {
  name                = "private-nsg-${terraform.workspace}"
  location            = azurerm_resource_group.tikweb_rg.location
  resource_group_name = azurerm_resource_group.tikweb_rg.name

  security_rule {
    name                       = "DenyAllInboundFromInternet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowAllInboundFromVnet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutboundToSpecificServices"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
}

resource "azurerm_subnet_network_security_group_association" "public_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.web-public-subnet.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "private_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.web-private-subnet.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}
