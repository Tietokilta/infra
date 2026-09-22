resource "cloudflare_dns_record" "tikpannu_a" {
  for_each = var.subdomains

  zone_id = var.cloudflare_zone_id
  name    = each.value
  type    = "A"
  content = var.tikpannu_ip
  proxied = false
  ttl     = 300
}

# Retain the record created before this module took a set of subdomains
moved {
  from = cloudflare_dns_record.tikpannu_a
  to   = cloudflare_dns_record.tikpannu_a["pannu"]
}
