resource "cloudflare_dns_record" "histotik_cname" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "CNAME"
  content = "${azurerm_cdn_endpoint.histotik_cdn_endpoint.name}.azureedge.net"
  proxied = false
  ttl     = 300
}

moved {
  from = cloudflare_dns_record.histotik_cname[0]
  to   = cloudflare_dns_record.histotik_cname
}
