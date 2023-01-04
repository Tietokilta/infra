output "resource_group_name" {
  value = azurerm_resource_group.dns_rg.name
}

output "root_zone_name" {
  value = azurerm_dns_zone.root_zone.name
}
