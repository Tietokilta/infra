resource "azurerm_resource_group" "dns_rg" {
  name     = "dns-m0-rg"
  location = var.resource_group_location
}

resource "azurerm_dns_zone" "root_zone" {
  name                = "muistinnollaus.fi"
  resource_group_name = "dns-m0-rg"
}

# CNAME record for www.
resource "azurerm_dns_cname_record" "www_cname" {
  name                = "www"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300
  record              = azurerm_dns_zone.root_zone.name
}
