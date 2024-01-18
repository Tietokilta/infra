

terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "2.19.0"
    }
  }
}

locals {
  fqdn = "${var.subdomain}.${var.root_zone_name}"
}
# A record for the web app
resource "azurerm_dns_a_record" "tikweb_a" {
  name                = var.subdomain
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = data.dns_a_record_set.tikweb_dns_fetch.addrs
}

# Azure verification key
resource "azurerm_dns_txt_record" "tikweb_asuid" {
  name                = "asuid.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.frontend.custom_domain_verification_id
  }
}


# Reporting-only DMARC policy
resource "azurerm_dns_txt_record" "tikweb_dmarc" {
  name                = "_dmarc.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  }
}
resource "azurerm_app_service_custom_hostname_binding" "tikweb_hostname_binding" {
  hostname            = local.fqdn
  app_service_name    = azurerm_linux_web_app.frontend.name
  resource_group_name = var.resource_group_name

  # Deletion may need manual work.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/11231
  # TODO: Add dependencies for creation
  depends_on = [
    azurerm_dns_a_record.tikweb_a,
    azurerm_dns_txt_record.tikweb_asuid
  ]
}
resource "random_password" "tikweb_cert_password" {
  length  = 48
  special = false
}

resource "acme_certificate" "tikweb_acme_cert" {
  account_key_pem          = var.acme_account_key
  common_name              = local.fqdn
  key_type                 = "2048" # RSA
  certificate_p12_password = random_password.tikweb_cert_password.result

  dns_challenge {
    provider = "azure"
    config = {
      AZURE_RESOURCE_GROUP = var.dns_resource_group_name
      AZURE_ZONE_NAME      = var.root_zone_name
    }
  }
}

resource "azurerm_app_service_certificate" "tikweb_cert" {
  name                = "tikweb-cert-${terraform.workspace}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  pfx_blob            = acme_certificate.tikweb_acme_cert.certificate_p12
  password            = acme_certificate.tikweb_acme_cert.certificate_p12_password
}

resource "azurerm_app_service_certificate_binding" "tikweb_cert_binding" {
  certificate_id      = azurerm_app_service_certificate.tikweb_cert.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.tikweb_hostname_binding.id
  ssl_state           = "SniEnabled"
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/14642#issuecomment-1084728235
# Currently, the azurerm provider doesn't give us the IP address, so we need to fetch it ourselves.
data "dns_a_record_set" "tikweb_dns_fetch" {
  host = azurerm_linux_web_app.frontend.default_hostname
}

resource "azurerm_dns_cname_record" "tikweb_cdn_cname_record" {
  name                = "cdn.${var.subdomain}"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  record              = azurerm_cdn_endpoint.next-cdn-endpoint.fqdn
}
