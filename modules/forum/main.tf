resource "azurerm_resource_group" "forum_rg" {
  name     = "vaalit-${var.env_name}-rg"
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "forum_vnet" {
  name                = "vaalit-${var.env_name}-vnet"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.forum_rg.location
  resource_group_name = azurerm_resource_group.forum_rg.name
}

resource "azurerm_subnet" "forum_subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.forum_rg.name
  virtual_network_name = azurerm_virtual_network.forum_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "forum_ip" {
  name                = "vaalit-${var.env_name}-ip"
  resource_group_name = azurerm_resource_group.forum_rg.name
  location            = azurerm_resource_group.forum_rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "forum_nic" {
  name                = "vaalit-${var.env_name}-nic"
  location            = azurerm_resource_group.forum_rg.location
  resource_group_name = azurerm_resource_group.forum_rg.name

  ip_configuration {
    name                          = "vaalit-ipconfig"
    subnet_id                     = azurerm_subnet.forum_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.forum_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "forum_nic_nsg" {
  network_interface_id      = azurerm_network_interface.forum_nic.id
  network_security_group_id = azurerm_network_security_group.forum_nsg.id
}

// reuse previously created VM disk
data "azurerm_managed_disk" "forum_disk" {
  resource_group_name = azurerm_resource_group.forum_rg.name
  name                = "vaalit-${var.env_name}-disk"
}

resource "azurerm_virtual_machine" "forum_vm" {
  name                  = "vaalit-${var.env_name}-vm"
  location              = azurerm_resource_group.forum_rg.location
  resource_group_name   = azurerm_resource_group.forum_rg.name
  network_interface_ids = [azurerm_network_interface.forum_nic.id]
  vm_size               = "Standard_B2s"

  delete_os_disk_on_termination = false

  storage_os_disk {
    create_option   = "Attach"
    name            = data.azurerm_managed_disk.forum_disk.name
    managed_disk_id = data.azurerm_managed_disk.forum_disk.id
    os_type         = "Linux"
  }
}
