terraform {
  required_providers {
    mailgun = {
      source = "wgebis/mailgun"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

# Mailgun domain
resource "mailgun_domain" "this" {
  name        = var.domain_name
  region      = "eu"
  spam_action = "disabled"
}

# DKIM - extract from Mailgun's sending_records_set
locals {
  # Find the DKIM record from Mailgun's output
  dkim_record = [
    for r in mailgun_domain.this.sending_records_set :
    r if r.record_type == "TXT" && can(regex("domainkey", r.name))
  ][0]
  # Mailgun returns FQDN like "mg._domainkey.ilmo.tietokilta.fi", strip the zone to get relative name
  dkim_record_name = trimsuffix(local.dkim_record.name, ".${var.dns_zone_name}")
}

resource "cloudflare_dns_record" "cf_mx_mxa" {
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mxa.eu.mailgun.org"
  priority = 10
  ttl      = 300
}

resource "cloudflare_dns_record" "cf_mx_mxb" {
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mxb.eu.mailgun.org"
  priority = 10
  ttl      = 300
}

resource "cloudflare_dns_record" "cf_spf" {
  count   = var.create_spf ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "TXT"
  content = "v=spf1 include:mailgun.org ~all"
  ttl     = 300
}

resource "cloudflare_dns_record" "cf_dkim" {
  zone_id = var.cloudflare_zone_id
  name    = local.dkim_record_name
  type    = "TXT"
  content = local.dkim_record.value
  ttl     = 300
}

resource "cloudflare_dns_record" "cf_dmarc" {
  zone_id = var.cloudflare_zone_id
  name    = "_dmarc.${var.subdomain}"
  type    = "TXT"
  content = "v=DMARC1;p=none;sp=none;rua=mailto:${var.dmarc_email}!10m;ruf=mailto:${var.dmarc_email}!10m"
  ttl     = 300
}

# State migrations from count-indexed to non-count resources
moved {
  from = cloudflare_dns_record.cf_mx_mxa[0]
  to   = cloudflare_dns_record.cf_mx_mxa
}
moved {
  from = cloudflare_dns_record.cf_mx_mxb[0]
  to   = cloudflare_dns_record.cf_mx_mxb
}
moved {
  from = cloudflare_dns_record.cf_dkim[0]
  to   = cloudflare_dns_record.cf_dkim
}
moved {
  from = cloudflare_dns_record.cf_dmarc[0]
  to   = cloudflare_dns_record.cf_dmarc
}

# Optional SMTP credential
resource "random_password" "smtp" {
  count   = var.create_smtp_credential ? 1 : 0
  length  = 32
  special = false
}

resource "mailgun_domain_credential" "this" {
  count = var.create_smtp_credential ? 1 : 0

  region   = "eu"
  domain   = mailgun_domain.this.name
  login    = var.smtp_login
  password = random_password.smtp[0].result

  lifecycle {
    ignore_changes = [password]
  }
}
