locals {
  db_name = "${var.env_name}_tentti_db"
}

resource "azurerm_resource_group" "tenttiarkisto_rg" {
  name     = "tenttiarkisto-${var.env_name}-rg"
  location = var.resource_group_location
}

resource "azurerm_postgresql_flexible_server_database" "tenttiarkisto_db_new" {
  name      = local.db_name
  server_id = var.postgres_server_id
  charset   = "utf8"
}

resource "azurerm_storage_account" "tenttiarkisto_storage_account" {
  name                            = "tenttiarkisto${var.env_name}sa"
  resource_group_name             = azurerm_resource_group.tenttiarkisto_rg.name
  location                        = azurerm_resource_group.tenttiarkisto_rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = true
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 14
    }
  }
}

resource "azurerm_storage_container" "tenttiarkisto_storage_container" {
  name                  = "exams"
  storage_account_id    = azurerm_storage_account.tenttiarkisto_storage_account.id
  container_access_type = "blob"
}

resource "azurerm_linux_web_app" "tenttiarkisto" {
  name                = "tenttiarkisto-${var.env_name}-app"
  location            = var.tikweb_app_plan_rg_location
  resource_group_name = var.tikweb_app_plan_rg_name
  service_plan_id     = var.tikweb_app_plan_id

  https_only = true

  site_config {
    ftps_state = "Disabled"
    always_on  = true

    application_stack {
      docker_registry_url = "https://ghcr.io"
      docker_image_name   = "tietokilta/tenttiarkisto:latest"
    }
  }

  logs {
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 100
      }
    }
  }

  app_settings = {
    WEBSITES_PORT = 8000

    EXAM_ACCOUNT_NAME = azurerm_storage_account.tenttiarkisto_storage_account.name
    EXAM_ACCOUNT_KEY  = azurerm_storage_account.tenttiarkisto_storage_account.primary_access_key
    EXAM_CONTAINER    = azurerm_storage_container.tenttiarkisto_storage_container.name

    DB_NAME     = azurerm_postgresql_flexible_server_database.tenttiarkisto_db_new.name
    DB_USER     = "tietokilta"
    DB_PASSWORD = var.postgres_admin_password
    DB_HOST     = var.postgres_server_fqdn

    SECRET_KEY = var.django_secret_key

    ALLOWED_HOSTS = "tenttiarkisto-${var.env_name}-app.azurewebsites.net,tenttiarkisto.fi,www.tenttiarkisto.fi"
  }

  lifecycle {
    ignore_changes = [
      site_config.0.application_stack, # deployments are made outside of Terraform
    ]
  }
}

resource "azurerm_dns_zone" "tenttiarkisto_zone" {
  name                = "tenttiarkisto.fi"
  resource_group_name = var.tikweb_app_plan_rg_name
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/14642#issuecomment-1084728235
# Currently, the azurerm provider doesn't give us the IP address, so we need to fetch it ourselves.
data "dns_a_record_set" "tenttiarkisto_dns_fetch" {
  host = azurerm_linux_web_app.tenttiarkisto.default_hostname
}

resource "azurerm_dns_a_record" "tenttiarkisto_a" {
  name                = "@"
  resource_group_name = var.tikweb_app_plan_rg_name
  zone_name           = azurerm_dns_zone.tenttiarkisto_zone.name
  ttl                 = 300
  records             = data.dns_a_record_set.tenttiarkisto_dns_fetch.addrs
}

resource "azurerm_dns_cname_record" "tenttiarkisto_cname_www" {
  name                = "www"
  resource_group_name = var.tikweb_app_plan_rg_name
  zone_name           = azurerm_dns_zone.tenttiarkisto_zone.name
  ttl                 = 300
  record              = azurerm_linux_web_app.tenttiarkisto.default_hostname
}

resource "azurerm_dns_txt_record" "tenttiarkisto_txt_asuid" {
  name                = "asuid"
  resource_group_name = var.tikweb_app_plan_rg_name
  zone_name           = azurerm_dns_zone.tenttiarkisto_zone.name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.tenttiarkisto.custom_domain_verification_id
  }
}

resource "azurerm_dns_txt_record" "tenttiarkisto_www_txt_asuid" {
  name                = "asuid.www"
  resource_group_name = var.tikweb_app_plan_rg_name
  zone_name           = azurerm_dns_zone.tenttiarkisto_zone.name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.tenttiarkisto.custom_domain_verification_id
  }
}

resource "azurerm_app_service_custom_hostname_binding" "tenttiarkisto_hostname_binding" {
  resource_group_name = var.tikweb_app_plan_rg_name
  app_service_name    = azurerm_linux_web_app.tenttiarkisto.name
  hostname            = "tenttiarkisto.fi"

  # lifecycle {
  #   ignore_changes = [ssl_state, thumbprint]
  # }

  depends_on = [
    azurerm_dns_txt_record.tenttiarkisto_txt_asuid,
  ]
}

resource "azurerm_app_service_managed_certificate" "tenttiarkisto_cert" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.tenttiarkisto_hostname_binding.id
}

resource "azurerm_app_service_certificate_binding" "tenttiarkisto_cert_binding" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.tenttiarkisto_hostname_binding.id
  certificate_id      = azurerm_app_service_managed_certificate.tenttiarkisto_cert.id
  ssl_state           = "SniEnabled"
}

resource "azurerm_app_service_custom_hostname_binding" "tenttiarkisto_www_hostname_binding" {
  resource_group_name = var.tikweb_app_plan_rg_name
  app_service_name    = azurerm_linux_web_app.tenttiarkisto.name
  hostname            = "www.tenttiarkisto.fi"

  # lifecycle {
  #   ignore_changes = [ssl_state, thumbprint]
  # }

  depends_on = [
    azurerm_dns_cname_record.tenttiarkisto_cname_www,
    azurerm_dns_txt_record.tenttiarkisto_www_txt_asuid
  ]
}

resource "azurerm_app_service_managed_certificate" "tenttiarkisto_www_cert" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.tenttiarkisto_www_hostname_binding.id
}

resource "azurerm_app_service_certificate_binding" "tenttiarkisto_www_cert_binding" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.tenttiarkisto_www_hostname_binding.id
  certificate_id      = azurerm_app_service_managed_certificate.tenttiarkisto_www_cert.id
  ssl_state           = "SniEnabled"
}
