resource "azurerm_resource_group" "dns_rg" {
  name     = "dns-${var.env_name}-rg"
  location = var.resource_group_location
}

resource "azurerm_dns_zone" "root_zone" {
  name                = var.zone_name
  resource_group_name = azurerm_resource_group.dns_rg.name
}
