terraform {
  required_providers {
    acme = {
      source = "vancluever/acme"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

locals {
  fqdn           = var.subdomain == "@" ? var.root_zone_name : "${var.subdomain}.${var.root_zone_name}"
  asuid_domain   = var.subdomain == "@" ? "" : ".${var.subdomain}"
  is_root_domain = var.subdomain == "@"
}

data "dns_a_record_set" "app_dns_fetch" {
  host = var.app_service_default_hostname
}

resource "cloudflare_dns_record" "app_a_record" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "A"
  content = data.dns_a_record_set.app_dns_fetch.addrs[0]
  proxied = var.proxied
  ttl     = var.proxied ? 1 : 300
}

# asuid TXT required by Azure App Service for hostname binding verification
resource "cloudflare_dns_record" "app_asuid_record" {
  zone_id = var.cloudflare_zone_id
  name    = "asuid${local.asuid_domain}"
  type    = "TXT"
  content = var.custom_domain_verification_id
  ttl     = 300
}

resource "cloudflare_dns_record" "www_cname" {
  count   = local.is_root_domain ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "www"
  type    = "CNAME"
  content = local.fqdn
  proxied = var.proxied
  ttl     = var.proxied ? 1 : 300
}

resource "cloudflare_dns_record" "www_asuid_record" {
  count   = local.is_root_domain ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "asuid.www"
  type    = "TXT"
  content = var.custom_domain_verification_id
  ttl     = 300
}

# State migrations from count-indexed to non-count resources
moved {
  from = cloudflare_dns_record.app_a_record[0]
  to   = cloudflare_dns_record.app_a_record
}
moved {
  from = cloudflare_dns_record.app_asuid_record[0]
  to   = cloudflare_dns_record.app_asuid_record
}

resource "azurerm_app_service_custom_hostname_binding" "app_hostname_binding" {
  hostname            = local.fqdn
  app_service_name    = var.app_service_name
  resource_group_name = var.app_service_resource_group_name

  depends_on = [
    cloudflare_dns_record.app_a_record,
    cloudflare_dns_record.app_asuid_record,
  ]
}

resource "azurerm_app_service_custom_hostname_binding" "www_hostname_binding" {
  count               = local.is_root_domain ? 1 : 0
  hostname            = "www.${local.fqdn}"
  app_service_name    = var.app_service_name
  resource_group_name = var.app_service_resource_group_name

  depends_on = [
    cloudflare_dns_record.www_cname,
    cloudflare_dns_record.www_asuid_record,
  ]
}

# Certificate
resource "random_password" "app_cert_password" {
  length  = 48
  special = false
}

resource "acme_certificate" "app_acme_cert" {
  account_key_pem           = var.acme_account_key
  common_name               = local.fqdn
  subject_alternative_names = local.is_root_domain ? ["www.${local.fqdn}"] : []
  key_type                  = "2048" # RSA
  certificate_p12_password  = random_password.app_cert_password.result

  dns_challenge {
    provider = "cloudflare"
    config = {
      CF_DNS_API_TOKEN = var.cloudflare_api_token
    }
  }
}

resource "azurerm_app_service_certificate" "app_cert" {
  name                = var.certificate_name
  resource_group_name = var.app_service_resource_group_name
  location            = var.app_service_location
  pfx_blob            = acme_certificate.app_acme_cert.certificate_p12
  password            = acme_certificate.app_acme_cert.certificate_p12_password
}

# Certificate Bindings
resource "azurerm_app_service_certificate_binding" "app_cert_binding" {
  certificate_id      = azurerm_app_service_certificate.app_cert.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.app_hostname_binding.id
  ssl_state           = "SniEnabled"
}

resource "azurerm_app_service_certificate_binding" "www_cert_binding" {
  count               = local.is_root_domain ? 1 : 0
  certificate_id      = azurerm_app_service_certificate.app_cert.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.www_hostname_binding[0].id
  ssl_state           = "SniEnabled"
}
