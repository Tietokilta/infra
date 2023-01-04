# A record for Discourse
resource "azurerm_dns_a_record" "forum_a" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = [data.azurerm_public_ip.forum_ip.ip_address]
}

# Currently used MX records for smtp.tietokilta.fi
resource "azurerm_dns_mx_record" "smtp_mx" {
  name                = "smtp"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    preference = 10
    exchange   = "mxa.eu.mailgun.org"
  }
}

# Currently used SPF record for smtp.tietokilta.fi
resource "azurerm_dns_txt_record" "smtp_spf" {
  name                = "smtp"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=spf1 include:mailgun.org ~all"
  }
}

# Currently used DKIM key for smtp.tietokilta.fi
resource "azurerm_dns_txt_record" "smtp_dkim_k1" {
  name                = "k1._domainkey.smtp"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDen0O6a0wHtCz71H8MBHurESFGVS7tILlb5bKi6yGTlCktfafMbD+BQNFeYpeuTVhtt4NbUBF8ta1qHbUF0wLCr8nVmORaC81eQ1jo/qk0qOqTSR/cvFrrqY7s3ef1BBhM6d484jjtmMsxBjpGMqSmmYfNU/irA6j5Mpmi12DNcwIDAQAB"
  }
}

# DKIM key, name implies Discourse but doesn't seem to be currently in use
resource "azurerm_dns_txt_record" "discourse_dkim_smtp" {
  name                = "smtp._domainkey.discourse"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDuwC0SuHoe6L8Nc+vybqPs2I1mgtyW5QryKfBI7UaKxxcqq2a3/DN/dJa3x5wMo0mJbM14OqYCpVH5ydq/nCZTPOPVxMacwqT5uDGPBjeugJZRIH0Cx1kloF5cy9B/ZoLnnZMleN/N5wkb848OWlJ0wNbAAmrsO1XY+xQLkGknwIDAQAB"
  }
}

# MX records for Mailgun
resource "azurerm_dns_mx_record" "forum_mx" {
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
resource "azurerm_dns_txt_record" "forum_spf" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=spf1 mx include:mailgun.org ~all"
  }
}

# DKIM key for Mailgun
resource "azurerm_dns_txt_record" "forum_dkim" {
  name                = "${var.dkim_selector}._domainkey.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = var.dkim_key
  }
}

# Reporting-only DMARC policy
resource "azurerm_dns_txt_record" "forum_dmarc" {
  name                = "_dmarc.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  }
}
