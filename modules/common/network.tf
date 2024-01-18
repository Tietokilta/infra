
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
  delegation {
    name = "webappdelegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

}
resource "azurerm_subnet" "web-private-subnet" {
  name                 = "web-private-subnet-${terraform.workspace}"
  resource_group_name  = azurerm_resource_group.tikweb_rg.name
  virtual_network_name = azurerm_virtual_network.tiknet.name
  address_prefixes     = ["10.1.2.0/24"]
  service_endpoints    = ["Microsoft.AzureCosmosDB"]
  delegation {
    name = "webappdelegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

}
resource "azurerm_subnet" "web-private-storage-subnet" {
  name                 = "web-private-storage-subnet-${terraform.workspace}"
  resource_group_name  = azurerm_resource_group.tikweb_rg.name
  virtual_network_name = azurerm_virtual_network.tiknet.name
  address_prefixes     = ["10.1.3.0/24"]
}

resource "azurerm_private_dns_zone_virtual_network_link" "tiknet-private-dns-vnet-link" {
  name                  = "tiknet-private-dns-vnet-link-${terraform.workspace}"
  private_dns_zone_name = var.dns_private_zone_name
  virtual_network_id    = azurerm_virtual_network.tiknet.id
  resource_group_name   = var.dns_rg_name
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
