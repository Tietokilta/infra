# MX records for Mailgun
resource "azurerm_dns_mx_record" "m0_mx" {
  name                = var.mail_subdomain
  resource_group_name = var.mail_dns_resource_group_name
  zone_name           = var.mail_dns_zone_name
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
resource "azurerm_dns_txt_record" "m0_spf" {
  name                = var.mail_subdomain
  resource_group_name = var.mail_dns_resource_group_name
  zone_name           = var.mail_dns_zone_name
  ttl                 = 300

  record {
    value = "v=spf1 include:mailgun.org ~all"
  }
}

# DKIM key for Mailgun
resource "azurerm_dns_txt_record" "m0_dkim" {
  name                = "${var.dkim_selector}._domainkey.${var.mail_subdomain}"
  resource_group_name = var.mail_dns_resource_group_name
  zone_name           = var.mail_dns_zone_name
  ttl                 = 300

  record {
    value = var.dkim_key
  }
}
# Email click tracking CNAME for Mailgun
resource "azurerm_dns_cname_record" "m0_cname_email" {
  name                = "email.${var.mail_subdomain}"
  resource_group_name = var.mail_dns_resource_group_name
  zone_name           = var.mail_dns_zone_name
  ttl                 = 300
  record              = "eu.mailgun.org"
}

# Reporting-only DMARC policy
resource "azurerm_dns_txt_record" "m0_dmarc" {
  name                = "_dmarc"
  resource_group_name = var.m0_dns_resource_group_name
  zone_name           = var.m0_dns_zone_name
  ttl                 = 300

  record {
    value = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  }
}


