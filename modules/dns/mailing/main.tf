terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

locals {
  fqdn           = "${var.subdomain}.${var.root_zone_name}"
  use_cloudflare = var.cloudflare_zone_id != ""
}

# Email click tracking CNAME for Mailgun
resource "azurerm_dns_cname_record" "list_cname_link" {
  name                = "link.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  record              = "eu.mailgun.org"
}

# MX records for Mailgun
resource "azurerm_dns_mx_record" "list_mx" {
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
resource "azurerm_dns_txt_record" "list_spf" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=spf1 include:mailgun.org ~all"
  }
}

# DKIM key for Mailgun
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

# Cloudflare DNS records (mirroring Azure records when cloudflare_zone_id is set)
resource "cloudflare_dns_record" "list_cname_link" {
  count   = local.use_cloudflare ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "link.${var.subdomain}"
  type    = "CNAME"
  content = "eu.mailgun.org"
  proxied = false
  ttl     = 300
}

resource "cloudflare_dns_record" "list_mx_mxa" {
  count    = local.use_cloudflare ? 1 : 0
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mxa.eu.mailgun.org"
  priority = 10
  ttl      = 300
}

resource "cloudflare_dns_record" "list_mx_mxb" {
  count    = local.use_cloudflare ? 1 : 0
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mxb.eu.mailgun.org"
  priority = 10
  ttl      = 300
}

resource "cloudflare_dns_record" "list_spf" {
  count   = local.use_cloudflare ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "TXT"
  content = "v=spf1 include:mailgun.org ~all"
  ttl     = 300
}

resource "cloudflare_dns_record" "list_dkim" {
  count   = local.use_cloudflare ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "${var.dkim_selector}._domainkey.${var.subdomain}"
  type    = "TXT"
  content = var.dkim_key
  ttl     = 300
}

resource "cloudflare_dns_record" "list_dmarc" {
  count   = local.use_cloudflare ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "_dmarc.${var.subdomain}"
  type    = "TXT"
  content = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  ttl     = 300
}
