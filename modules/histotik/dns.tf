resource "cloudflare_dns_record" "histotik_cname" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "CNAME"
  content = "tietokilta.github.io"
  proxied = false
  ttl     = 300
}
