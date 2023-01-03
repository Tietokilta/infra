locals {
  fqdn = "${var.subdomain}.${var.root_zone_name}"
}

# A record for Mailman
resource "azurerm_dns_a_record" "list_a" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = ["130.233.48.30"]
}

# MX records for Mailman
resource "azurerm_dns_mx_record" "list_mx" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    preference = 20
    exchange   = "tietokilta.fi"
  }
  record {
    preference = 21
    exchange   = "mail.cs.hut.fi"
  }
}

# SPF record
resource "azurerm_dns_txt_record" "list_spf" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=spf1 mx include:mailgun.org ~all"
  }
}

# DKIM key for Mailgun (Mailman doesn't sign emails)
resource "azurerm_dns_txt_record" "list_dkim" {
  name                = "${var.dkim_selector}._domainkey.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = var.dkim_key
  }
}

# Reporting-only DMARC policy
resource "azurerm_dns_txt_record" "list_dmarc" {
  name                = "_dmarc.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  }
}
