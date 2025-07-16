output "forum_ip" {
  value = azurerm_public_ip.forum_ip.ip_address
}

output "fqdn" {
  value = local.fqdn
}
