resource "azurerm_dns_cname_record" "histotik_cname_record" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  record              = "${azurerm_cdn_endpoint.histotik_cdn_endpoint.name}.azureedge.net"
  # TODO: use .fqdn when azurerm provider has been upgraded
}

# TODO: add histo.tik.tietokilta.fi
