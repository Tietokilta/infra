resource "azurerm_network_security_group" "forum_nsg" {
  name                = "vaalit-${var.env_name}-nsg"
  location            = azurerm_resource_group.forum_rg.location
  resource_group_name = azurerm_resource_group.forum_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 300
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    access                     = "Allow"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 320
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
    access                     = "Allow"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 340
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "80"
    access                     = "Allow"
  }

  security_rule {
    name                       = "TikBot-webhook"
    priority                   = 350
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "4000"
    access                     = "Allow"
  }

  security_rule {
    name                       = "Marttabot"
    priority                   = 360
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "8443"
    access                     = "Allow"
  }

  security_rule {
    name                       = "MarttabotAPP"
    priority                   = 370
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "3005"
    access                     = "Allow"
  }
}
