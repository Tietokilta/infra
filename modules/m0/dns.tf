terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "2.19.0"
    }
  }
}

resource "azurerm_resource_group" "dns_rg" {
  name     = "dns-m0-rg"
  location = var.resource_group_location
}

resource "azurerm_dns_zone" "m0_zone" {
  name                = "muistinnollaus.fi"
  resource_group_name = azurerm_resource_group.dns_rg.name
}

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
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.m0_zone.name
  ttl                 = 300

  record {
    value = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  }
}

#A record for the web app
resource "azurerm_dns_a_record" "m0_a" {
  name                = "@"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.m0_zone.name
  ttl                 = 300
  records             = data.dns_a_record_set.m0_dns_fetch.addrs
}

# CNAME record for www.
resource "azurerm_dns_cname_record" "www_cname" {
  name                = "www"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.m0_zone.name
  ttl                 = 300
  record              = azurerm_dns_zone.m0_zone.name
}

# Azure verification key
resource "azurerm_dns_txt_record" "m0_asuid" {
  name                = "asuid"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.m0_zone.name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.frontend.custom_domain_verification_id
  }
}

# Azure verification key
resource "azurerm_dns_txt_record" "m0_www_asuid" {
  name                = "asuid.www"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.m0_zone.name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.frontend.custom_domain_verification_id
  }
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/14642#issuecomment-1084728235
# Currently, the azurerm provider doesn't give us the IP address, so we need to fetch it ourselves.
data "dns_a_record_set" "m0_dns_fetch" {
  host = azurerm_linux_web_app.frontend.default_hostname
}
