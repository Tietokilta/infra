resource "azurerm_resource_group" "voo_rg" {
  name     = "voo-${var.env_name}-rg"
  location = var.resource_group_location
}

resource "azurerm_dns_zone" "voo_zone" {
  name                = "varjoopintoopas.fi"
  resource_group_name = azurerm_resource_group.voo_rg.name
}

resource "azurerm_dns_a_record" "voo_a" {
  name                = "@"
  resource_group_name = azurerm_resource_group.voo_rg.name
  zone_name           = azurerm_dns_zone.voo_zone.name
  ttl                 = 300
  records             = ["130.233.48.30"]
}

resource "azurerm_dns_cname_record" "voo_cname_www" {
  name                = "www"
  resource_group_name = azurerm_resource_group.voo_rg.name
  zone_name           = azurerm_dns_zone.voo_zone.name
  ttl                 = 300
  record              = "varjoopintoopas.fi"
}
