resource "azurerm_resource_group" "dns_rg" {
  name     = "dns-${var.env_name}-rg"
  location = var.resource_group_location
}

resource "azurerm_dns_zone" "root_zone" {
  name                = var.zone_name
  resource_group_name = azurerm_resource_group.dns_rg.name
}

# A record for main website
resource "azurerm_dns_a_record" "root_a" {
  name                = "@"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300
  records             = ["130.233.48.30"]
}

# record for old website
resource "azurerm_dns_a_record" "old_a" {
  name                = "old"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300
  records             = ["130.233.48.30"]
}

# CNAME record for www.
resource "azurerm_dns_cname_record" "www_cname" {
  name                = "www"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300
  record              = azurerm_dns_zone.root_zone.name
}
