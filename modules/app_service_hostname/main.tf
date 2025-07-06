terraform {
  required_providers {
    acme = {
      source = "vancluever/acme"
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

# Root/subdomain records
resource "azurerm_dns_a_record" "app_a_record" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = data.dns_a_record_set.app_dns_fetch.addrs
}

resource "azurerm_dns_txt_record" "app_asuid_record" {
  name                = "asuid${local.asuid_domain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = var.custom_domain_verification_id
  }
}

resource "azurerm_app_service_custom_hostname_binding" "app_hostname_binding" {
  hostname            = local.fqdn
  app_service_name    = var.app_service_name
  resource_group_name = var.app_service_resource_group_name

  depends_on = [
    azurerm_dns_a_record.app_a_record,
    azurerm_dns_txt_record.app_asuid_record
  ]
}

# WWW records (only for root domains)
resource "azurerm_dns_cname_record" "www_cname" {
  count               = local.is_root_domain ? 1 : 0
  name                = "www"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  record              = local.fqdn
}

resource "azurerm_dns_txt_record" "www_asuid_record" {
  count               = local.is_root_domain ? 1 : 0
  name                = "asuid.www"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = var.custom_domain_verification_id
  }
}

resource "azurerm_app_service_custom_hostname_binding" "www_hostname_binding" {
  count               = local.is_root_domain ? 1 : 0
  hostname            = "www.${local.fqdn}"
  app_service_name    = var.app_service_name
  resource_group_name = var.app_service_resource_group_name

  depends_on = [
    azurerm_dns_cname_record.www_cname,
    azurerm_dns_txt_record.www_asuid_record
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
    provider = "azuredns"
    config = {
      AZURE_RESOURCE_GROUP = var.dns_resource_group_name
      AZURE_ZONE_NAME      = var.root_zone_name
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