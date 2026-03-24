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

resource "cloudflare_dns_record" "tikpannu_a" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "A"
  content = var.tikpannu_ip
  proxied = false
  ttl     = 300
}
