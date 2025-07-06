# MX records for Mailgun
resource "azurerm_dns_mx_record" "invoicing_mx" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    preference = 10
    exchange   = "mxa.eu.mailgun.org"
  }

  record {
    preference = 10
    exchange   = "mxb.eu.mailgun.org"
  }
}

# SPF record for Mailgun
resource "azurerm_dns_txt_record" "invoicing_spf" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=spf1 include:mailgun.org ~all"
  }
}

# DKIM key for Mailgun
resource "azurerm_dns_txt_record" "invoicing_dkim" {
  name                = "${var.dkim_selector}._domainkey.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = var.dkim_key
  }
}

# Reporting-only DMARC policy
resource "azurerm_dns_txt_record" "invoicing_dmarc" {
  name                = "_dmarc.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  }
}


