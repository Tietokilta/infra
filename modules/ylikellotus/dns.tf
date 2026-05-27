locals {
  github_pages_ips = [
    "185.199.108.153",
    "185.199.109.153",
    "185.199.110.153",
    "185.199.111.153",
  ]
}

resource "cloudflare_dns_record" "apex_a" {
  for_each = toset(local.github_pages_ips)

  zone_id = var.cloudflare_zone_id
  name    = "@"
  type    = "A"
  content = each.value
  proxied = false
  ttl     = 300
}

resource "cloudflare_dns_record" "www_cname" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  type    = "CNAME"
  content = "ylikellotus.fi"
  proxied = false
  ttl     = 300
}
