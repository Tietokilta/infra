module "mailgun" {
  source = "../../mailgun-domain"

  domain_name             = "${var.subdomain}.${var.root_zone_name}"
  subdomain               = var.subdomain
  dns_resource_group_name = var.dns_resource_group_name
  dns_zone_name           = var.root_zone_name
  create_smtp_credential  = false # Uses existing keyvault credentials
  create_spf              = false # SPF is in combined TXT record with Google site verification
}
