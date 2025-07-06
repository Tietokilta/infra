locals {
  dns_rg_name = var.resource_group_name == null ? azurerm_resource_group.dns_rg[0].name : var.resource_group_name
}
resource "azurerm_resource_group" "dns_rg" {
  count    = var.resource_group_name == null ? 1 : 0
  name     = "dns-${var.env_name}-rg"
  location = var.resource_group_location
}

resource "azurerm_dns_zone" "root_zone" {
  name                = var.zone_name
  resource_group_name = local.dns_rg_name
  # Recreating root zone will change NS records, which will cause downtime due to long TTLs
  lifecycle {
    prevent_destroy = true
  }
}
