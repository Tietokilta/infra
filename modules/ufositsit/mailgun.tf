module "mailgun" {
  source = "../mailgun-domain"

  domain_name            = var.root_zone_name
  subdomain              = "@"
  dns_zone_name          = var.root_zone_name
  create_smtp_credential = true
  smtp_login             = "ufositsit-app"
  cloudflare_zone_id     = var.cloudflare_zone_id
}
