output "resource_group_name" {
  value = azurerm_resource_group.dns_rg.name
}

output "root_zone_name" {
  value = azurerm_dns_zone.root_zone.name
}
output "private_root_zone_name" {
  value = azurerm_private_dns_zone.private_root_zone.name
}