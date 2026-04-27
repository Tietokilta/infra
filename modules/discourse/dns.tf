resource "cloudflare_dns_record" "discourse_a" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "A"
  content = var.discourse_ip
  proxied = false
  ttl     = 300
}

resource "cloudflare_dns_record" "discourse_mx_mxa" {
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mxa.eu.mailgun.org"
  priority = 10
  ttl      = 300
}

resource "cloudflare_dns_record" "discourse_mx_mxb" {
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mxb.eu.mailgun.org"
  priority = 10
  ttl      = 300
}

resource "cloudflare_dns_record" "discourse_spf" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "TXT"
  content = "v=spf1 include:mailgun.org ~all"
  ttl     = 300
}

resource "cloudflare_dns_record" "discourse_dkim" {
  zone_id = var.cloudflare_zone_id
  name    = "${var.dkim_selector}._domainkey.${var.subdomain}"
  type    = "TXT"
  content = var.dkim_key
  ttl     = 300
}

resource "cloudflare_dns_record" "discourse_dmarc" {
  zone_id = var.cloudflare_zone_id
  name    = "_dmarc.${var.subdomain}"
  type    = "TXT"
  content = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  ttl     = 300
}

# State migrations from count-indexed to non-count resources
moved {
  from = cloudflare_dns_record.discourse_a[0]
  to   = cloudflare_dns_record.discourse_a
}
moved {
  from = cloudflare_dns_record.discourse_mx_mxa[0]
  to   = cloudflare_dns_record.discourse_mx_mxa
}
moved {
  from = cloudflare_dns_record.discourse_mx_mxb[0]
  to   = cloudflare_dns_record.discourse_mx_mxb
}
moved {
  from = cloudflare_dns_record.discourse_spf[0]
  to   = cloudflare_dns_record.discourse_spf
}
moved {
  from = cloudflare_dns_record.discourse_dkim[0]
  to   = cloudflare_dns_record.discourse_dkim
}
moved {
  from = cloudflare_dns_record.discourse_dmarc[0]
  to   = cloudflare_dns_record.discourse_dmarc
}
