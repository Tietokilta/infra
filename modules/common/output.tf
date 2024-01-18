output "resource_group_name" {
  value = azurerm_resource_group.tikweb_rg.name
}
output "resource_group_location" {
  value = azurerm_resource_group.tikweb_rg.location
}

output "postgres_admin_password" {
  value     = azurerm_postgresql_flexible_server.tikweb_pg_new.administrator_password
  sensitive = true
}

output "postgres_admin_username" {
  value     = azurerm_postgresql_flexible_server.tikweb_pg_new.administrator_login
  sensitive = true
}

output "postgres_server_id" {
  value = azurerm_postgresql_flexible_server.tikweb_pg_new.id
}

output "postgres_server_fqdn" {
  value = azurerm_postgresql_flexible_server.tikweb_pg_new.fqdn
}
output "postgres_server_name" {
  value = azurerm_postgresql_flexible_server.tikweb_pg_new.name
}
output "tikweb_app_plan_id" {
  value = azurerm_service_plan.tikweb_plan.id
}

output "acme_account_key" {
  value     = acme_registration.acme_reg.account_key_pem
  sensitive = true
}
output "tiknet_virtual_network_name" {
  value = azurerm_virtual_network.tiknet.name
}

output "tiknet_public_subnet_name" {
  value = azurerm_subnet.web-public-subnet.name
}
output "tiknet_public_subnet_id" {
  value = azurerm_subnet.web-public-subnet.id
}
output "tiknet_private_subnet_name" {
  value = azurerm_subnet.web-private-subnet.name
}
output "tiknet_private_subnet_id" {
  value = azurerm_subnet.web-private-subnet.id
}
