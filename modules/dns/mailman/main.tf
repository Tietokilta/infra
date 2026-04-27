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

# Cloudflare DNS records (created alongside Azure records before NS flip)
resource "cloudflare_dns_record" "list_a" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "A"
  content = "130.233.48.30"
  proxied = false
  ttl     = 300
}

resource "cloudflare_dns_record" "list_mx_tietokilta" {
  count    = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "tietokilta.fi"
  priority = 20
  ttl      = 300
}

resource "cloudflare_dns_record" "list_mx_mail_cs_hut" {
  count    = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mail.cs.hut.fi"
  priority = 21
  ttl      = 300
}

resource "cloudflare_dns_record" "list_spf" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "TXT"
  content = "v=spf1 mx include:mailgun.org ~all"
  ttl     = 300
}

resource "cloudflare_dns_record" "list_dkim" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "${var.dkim_selector}._domainkey.${var.subdomain}"
  type    = "TXT"
  content = var.dkim_key
  ttl     = 300
}

resource "cloudflare_dns_record" "list_dmarc" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "_dmarc.${var.subdomain}"
  type    = "TXT"
  content = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  ttl     = 300
}
