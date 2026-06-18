resource "cloudflare_dns_record" "tikpannu_a" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "A"
  content = var.tikpannu_ip
  proxied = false
  ttl     = 300
}
