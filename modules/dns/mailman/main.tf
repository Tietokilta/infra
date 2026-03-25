resource "cloudflare_dns_record" "list_a" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "A"
  content = "130.233.48.30"
  proxied = false
  ttl     = 300
}

resource "cloudflare_dns_record" "list_mx_tietokilta" {
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "tietokilta.fi"
  priority = 20
  ttl      = 300
}

resource "cloudflare_dns_record" "list_mx_mail_cs_hut" {
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mail.cs.hut.fi"
  priority = 21
  ttl      = 300
}

resource "cloudflare_dns_record" "list_spf" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "TXT"
  content = "v=spf1 mx include:mailgun.org ~all"
  ttl     = 300
}

resource "cloudflare_dns_record" "list_dkim" {
  zone_id = var.cloudflare_zone_id
  name    = "${var.dkim_selector}._domainkey.${var.subdomain}"
  type    = "TXT"
  content = var.dkim_key
  ttl     = 300
}

resource "cloudflare_dns_record" "list_dmarc" {
  zone_id = var.cloudflare_zone_id
  name    = "_dmarc.${var.subdomain}"
  type    = "TXT"
  content = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  ttl     = 300
}

# State migrations from count-indexed to non-count resources
moved {
  from = cloudflare_dns_record.list_a[0]
  to   = cloudflare_dns_record.list_a
}
moved {
  from = cloudflare_dns_record.list_mx_tietokilta[0]
  to   = cloudflare_dns_record.list_mx_tietokilta
}
moved {
  from = cloudflare_dns_record.list_mx_mail_cs_hut[0]
  to   = cloudflare_dns_record.list_mx_mail_cs_hut
}
moved {
  from = cloudflare_dns_record.list_spf[0]
  to   = cloudflare_dns_record.list_spf
}
moved {
  from = cloudflare_dns_record.list_dkim[0]
  to   = cloudflare_dns_record.list_dkim
}
moved {
  from = cloudflare_dns_record.list_dmarc[0]
  to   = cloudflare_dns_record.list_dmarc
}
