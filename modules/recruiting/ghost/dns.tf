resource "cloudflare_dns_record" "tikjob_txt_google_verification" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "TXT"
  content = "google-site-verification=CQLRUnnxEnLtINJtF6cyJJH3YQSA8dxD6ap3qmFma5M"
  ttl     = 300
}

resource "cloudflare_dns_record" "tikjob_spf" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "TXT"
  content = "v=spf1 include:mailgun.org ~all"
  ttl     = 300
}

resource "cloudflare_dns_record" "tikjob_cname_email" {
  zone_id = var.cloudflare_zone_id
  name    = "email.${var.subdomain}"
  type    = "CNAME"
  content = "eu.mailgun.org"
  proxied = false
  ttl     = 300
}

# State migrations from count-indexed to non-count resources
moved {
  from = cloudflare_dns_record.tikjob_txt_google_verification[0]
  to   = cloudflare_dns_record.tikjob_txt_google_verification
}
moved {
  from = cloudflare_dns_record.tikjob_spf[0]
  to   = cloudflare_dns_record.tikjob_spf
}
moved {
  from = cloudflare_dns_record.tikjob_cname_email[0]
  to   = cloudflare_dns_record.tikjob_cname_email
}
