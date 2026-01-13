# A record for Discourse
resource "azurerm_dns_a_record" "forum_old_a" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = [azurerm_public_ip.forum_ip.ip_address]
}
