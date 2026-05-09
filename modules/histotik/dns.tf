resource "cloudflare_dns_record" "histotik_cname" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "CNAME"
  content = "tietokilta.github.io"
  proxied = false
  ttl     = 300
}

moved {
  from = cloudflare_dns_record.histotik_cname[0]
  to   = cloudflare_dns_record.histotik_cname
}
