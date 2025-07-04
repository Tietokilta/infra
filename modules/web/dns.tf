terraform {
  required_providers {
    acme = {
      source = "vancluever/acme"
    }
  }
}

locals {
  fqdn         = var.subdomain == "@" ? var.root_zone_name : "${var.subdomain}.${var.root_zone_name}"
  asuid_domain = var.subdomain == "@" ? "" : ".${var.subdomain}"
  www_domain   = var.subdomain == "@" ? "www" : "www.${var.subdomain}"
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
  name                = "asuid${local.asuid_domain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.web.custom_domain_verification_id
  }
}

# CNAME record for www.
resource "azurerm_dns_cname_record" "www_cname" {
  name                = local.www_domain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  record              = azurerm_linux_web_app.web.default_hostname
}
# Azure verification key for www
resource "azurerm_dns_txt_record" "tikweb_asuid_www" {
  name                = "asuid.www${local.asuid_domain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.web.custom_domain_verification_id
  }
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/14642#issuecomment-1084728235
# Currently, the azurerm provider doesn't give us the IP address, so we need to fetch it ourselves.
data "dns_a_record_set" "tikweb_dns_fetch" {
  host = azurerm_linux_web_app.web.default_hostname
}
