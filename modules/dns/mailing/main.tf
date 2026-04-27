terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

# Email click tracking CNAME for Mailgun
resource "cloudflare_dns_record" "list_cname_link" {
  zone_id = var.cloudflare_zone_id
  name    = "link.${var.subdomain}"
  type    = "CNAME"
  content = "eu.mailgun.org"
  proxied = false
  ttl     = 300
}

# MX records for Mailgun
resource "cloudflare_dns_record" "list_mx_mxa" {
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mxa.eu.mailgun.org"
  priority = 10
  ttl      = 300
}

resource "cloudflare_dns_record" "list_mx_mxb" {
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mxb.eu.mailgun.org"
  priority = 10
  ttl      = 300
}

# SPF record for Mailgun
resource "cloudflare_dns_record" "list_spf" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "TXT"
  content = "v=spf1 include:mailgun.org ~all"
  ttl     = 300
}

# DKIM key for Mailgun
resource "cloudflare_dns_record" "list_dkim" {
  zone_id = var.cloudflare_zone_id
  name    = "${var.dkim_selector}._domainkey.${var.subdomain}"
  type    = "TXT"
  content = var.dkim_key
  ttl     = 300
}

# Reporting-only DMARC policy
resource "cloudflare_dns_record" "list_dmarc" {
  zone_id = var.cloudflare_zone_id
  name    = "_dmarc.${var.subdomain}"
  type    = "TXT"
  content = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  ttl     = 300
}
