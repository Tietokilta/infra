terraform {
  required_providers {
    mailgun = {
      source = "wgebis/mailgun"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

locals {
  use_cloudflare = var.cloudflare_zone_id != ""
}

# Mailgun domain
resource "mailgun_domain" "this" {
  name        = var.domain_name
  region      = "eu"
  spam_action = "disabled"
}

# MX records for Mailgun
resource "azurerm_dns_mx_record" "mx" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.dns_zone_name
  ttl                 = 300

  record {
    preference = 10
    exchange   = "mxa.eu.mailgun.org"
  }
  record {
    preference = 10
    exchange   = "mxb.eu.mailgun.org"
  }
}

# SPF record (optional - disable if service manages its own combined TXT record)
resource "azurerm_dns_txt_record" "spf" {
  count = var.create_spf ? 1 : 0

  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.dns_zone_name
  ttl                 = 300

  record {
    value = "v=spf1 include:mailgun.org ~all"
  }
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

resource "azurerm_dns_txt_record" "dkim" {
  name                = local.dkim_record_name
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.dns_zone_name
  ttl                 = 300

  record {
    value = local.dkim_record.value
  }
}

# DMARC record
resource "azurerm_dns_txt_record" "dmarc" {
  name                = "_dmarc.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.dns_zone_name
  ttl                 = 300

  record {
    value = "v=DMARC1;p=none;sp=none;rua=mailto:${var.dmarc_email}!10m;ruf=mailto:${var.dmarc_email}!10m"
  }
}

# Cloudflare DNS records (mirroring Azure records when cloudflare_zone_id is set)
resource "cloudflare_dns_record" "cf_mx_mxa" {
  count    = local.use_cloudflare ? 1 : 0
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mxa.eu.mailgun.org"
  priority = 10
  ttl      = 300
}

resource "cloudflare_dns_record" "cf_mx_mxb" {
  count    = local.use_cloudflare ? 1 : 0
  zone_id  = var.cloudflare_zone_id
  name     = var.subdomain
  type     = "MX"
  content  = "mxb.eu.mailgun.org"
  priority = 10
  ttl      = 300
}

resource "cloudflare_dns_record" "cf_spf" {
  count   = local.use_cloudflare && var.create_spf ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "TXT"
  content = "v=spf1 include:mailgun.org ~all"
  ttl     = 300
}

resource "cloudflare_dns_record" "cf_dkim" {
  count   = local.use_cloudflare ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = local.dkim_record_name
  type    = "TXT"
  content = local.dkim_record.value
  ttl     = 300
}

resource "cloudflare_dns_record" "cf_dmarc" {
  count   = local.use_cloudflare ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "_dmarc.${var.subdomain}"
  type    = "TXT"
  content = "v=DMARC1;p=none;sp=none;rua=mailto:${var.dmarc_email}!10m;ruf=mailto:${var.dmarc_email}!10m"
  ttl     = 300
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
