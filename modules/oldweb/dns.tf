# A record for the web app
resource "azurerm_dns_a_record" "oldweb_a" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = data.dns_a_record_set.oldweb_dns_fetch.addrs
}

# Azure verification key
resource "azurerm_dns_txt_record" "oldweb_asuid" {
  name                = "asuid.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.oldweb_backend.custom_domain_verification_id
  }
}
