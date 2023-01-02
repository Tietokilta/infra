locals {
  mailman_subdomain = "list"
  mailman_fqdn      = "${local.mailman_subdomain}.${azurerm_dns_zone.root_zone.name}"
}

# A record for Mailman
resource "azurerm_dns_a_record" "list_a" {
  name                = local.mailman_subdomain
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300
  records             = ["130.233.48.30"]
}

# MX records for Mailman
resource "azurerm_dns_mx_record" "list_mx" {
  name                = local.mailman_subdomain
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
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
  name                = local.mailman_subdomain
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300

  record {
    value = "v=spf1 mx include:mailgun.org ~all"
  }
}

# DKIM key for Mailgun (Mailman doesn't sign emails)
resource "azurerm_dns_txt_record" "list_dkim" {
  name                = "mta._domainkey.${local.mailman_subdomain}"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300

  record {
    value = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDJN6WyS7YQcOKO4MKsSbrYfjL8hh24ot/0uQysHte3eqscbbwCFVlgmsg3423by3e20ZSBMhRXdtIkYdgn8wkfPyZlHVEOvOJBCR+tKqtexxQEbkk8LqmEzVggNZoLLX06wYNqt2Nxl++dlvUuB4IxmPPGQed3Xr7HBT8OZmKJYQIDAQAB"
  }
}

# Reporting-only DMARC policy
resource "azurerm_dns_txt_record" "list_dmarc" {
  name                = "_dmarc.${local.mailman_subdomain}"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300

  record {
    value = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  }
}

# Accept DMARC reports at root domain
resource "azurerm_dns_txt_record" "root_dmarc_reports_list" {
  name                = "${local.mailman_fqdn}._report._dmarc"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300

  record {
    value = "v=DMARC1;"
  }
}
