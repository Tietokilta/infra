resource "azurerm_dns_txt_record" "tikjob_txt" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  # Google site verification key
  record {
    value = "google-site-verification=CQLRUnnxEnLtINJtF6cyJJH3YQSA8dxD6ap3qmFma5M"
  }
  # SPF record for Mailgun
  record {
    value = "v=spf1 include:mailgun.org ~all"
  }
}

# Email click tracking CNAME for Mailgun
resource "azurerm_dns_cname_record" "tikjob_cname_email" {
  name                = "email.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  record              = "eu.mailgun.org"
}

# MX records for Mailgun
resource "azurerm_dns_mx_record" "tikjob_mx" {
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

# DKIM key for Mailgun
resource "azurerm_dns_txt_record" "tikjob_dkim" {
  name                = "${var.dkim_selector}._domainkey.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = var.dkim_key
  }
}

# Reporting-only DMARC policy
resource "azurerm_dns_txt_record" "tikjob_dmarc" {
  name                = "_dmarc.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  }
}
