

terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "2.19.0"
    }
  }
}

locals {
  fqdn = var.subdomain == "@" ? var.root_zone_name : "${var.subdomain}.${var.root_zone_name}"
}

# A record for the web app
resource "azurerm_dns_a_record" "tikweb_a" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = data.dns_a_record_set.tikweb_dns_fetch.addrs
}

# Azure verification key
resource "azurerm_dns_txt_record" "tikweb_asuid" {
  name                = "asuid.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.web.custom_domain_verification_id
  }
}

# Reporting-only DMARC policy
resource "azurerm_dns_txt_record" "tikweb_dmarc" {
  name                = "_dmarc.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  }
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/14642#issuecomment-1084728235
# Currently, the azurerm provider doesn't give us the IP address, so we need to fetch it ourselves.
data "dns_a_record_set" "tikweb_dns_fetch" {
  host = azurerm_linux_web_app.web.default_hostname
}
