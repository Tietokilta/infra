locals {
  fqdn = "${var.subdomain}.${var.root_zone_name}"
}

# A record for vaalit.tietokilta.fi
resource "azurerm_dns_a_record" "discourse_a" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = [var.discourse_ip]
}

# MX records for Mailgun
resource "azurerm_dns_mx_record" "discourse_mx" {
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
resource "azurerm_dns_txt_record" "discourse_spf" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=spf1 include:mailgun.org ~all"
  }
}

# DKIM key for Mailgun
resource "azurerm_dns_txt_record" "discourse_dkim" {
  name                = "${var.dkim_selector}._domainkey.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = var.dkim_key
  }
}

# Reporting-only DMARC policy
resource "azurerm_dns_txt_record" "discourse_dmarc" {
  name                = "_dmarc.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  }
}

# Cloudflare DNS records (created alongside Azure records before NS flip)
resource "cloudflare_dns_record" "discourse_a" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "A"
  content = var.discourse_ip
  proxied = false
  ttl     = 300
}

resource "cloudflare_dns_record" "discourse_mx_mxa" {
  count    = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mxa.eu.mailgun.org"
  priority = 10
  ttl      = 300
}

resource "cloudflare_dns_record" "discourse_mx_mxb" {
  count    = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mxb.eu.mailgun.org"
  priority = 10
  ttl      = 300
}

resource "cloudflare_dns_record" "discourse_spf" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "TXT"
  content = "v=spf1 include:mailgun.org ~all"
  ttl     = 300
}

resource "cloudflare_dns_record" "discourse_dkim" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "${var.dkim_selector}._domainkey.${var.subdomain}"
  type    = "TXT"
  content = var.dkim_key
  ttl     = 300
}

resource "cloudflare_dns_record" "discourse_dmarc" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "_dmarc.${var.subdomain}"
  type    = "TXT"
  content = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  ttl     = 300
}
