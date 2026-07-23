module "mailgun" {
  source = "../mailgun-domain"

  domain_name            = "${var.subdomain}.${var.root_zone_name}"
  subdomain              = var.subdomain
  dns_zone_name          = var.root_zone_name
  create_smtp_credential = true
  smtp_login             = "rekisteri-app"
  cloudflare_zone_id     = var.cloudflare_zone_id
}
