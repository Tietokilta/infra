# Combined TXT record with Google site verification and SPF
# Kept separate from mailgun module since it has non-mailgun records
resource "azurerm_dns_txt_record" "tikjob_txt" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  # Google site verification key
  record {
    value = "google-site-verification=CQLRUnnxEnLtINJtF6cyJJH3YQSA8dxD6ap3qmFma5M"
  }
  # SPF record for Mailgun
  record {
    value = "v=spf1 include:mailgun.org ~all"
  }
}

# Email click tracking CNAME for Mailgun
resource "azurerm_dns_cname_record" "tikjob_cname_email" {
  name                = "email.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  record              = "eu.mailgun.org"
}

# Cloudflare DNS records (when cloudflare_zone_id is set)
resource "cloudflare_dns_record" "tikjob_txt_google_verification" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "TXT"
  content = "google-site-verification=CQLRUnnxEnLtINJtF6cyJJH3YQSA8dxD6ap3qmFma5M"
  ttl     = 300
}

resource "cloudflare_dns_record" "tikjob_spf" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "TXT"
  content = "v=spf1 include:mailgun.org ~all"
  ttl     = 300
}

resource "cloudflare_dns_record" "tikjob_cname_email" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "email.${var.subdomain}"
  type    = "CNAME"
  content = "eu.mailgun.org"
  proxied = false
  ttl     = 300
}
