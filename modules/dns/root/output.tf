output "resource_group_name" {
  value = local.dns_rg_name
}

output "root_zone_name" {
  value = azurerm_dns_zone.root_zone.name
}
