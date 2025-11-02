locals {
  fqdn = "${var.subdomain}.${var.root_zone_name}"
}

# A record for pannu.tietokilta.fi
resource "azurerm_dns_a_record" "tikpannu_a" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = [var.tikpannu_ip]
}
