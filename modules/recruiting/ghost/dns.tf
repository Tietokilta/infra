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
