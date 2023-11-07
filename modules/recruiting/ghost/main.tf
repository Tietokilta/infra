terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "2.13.0-beta1"
    }
  }
}

locals {
  fqdn = "${var.subdomain}.${var.root_zone_name}"
}

resource "azurerm_service_plan" "tikjob_plan" {
  name                = "tikjob-${var.env_name}-plan"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  os_type  = "Linux"
  sku_name = "B1"
}

resource "azurerm_linux_web_app" "tikjob_ghost" {
  name                = "tikjob-${var.env_name}-app-ghost"
  location            = var.tikweb_rg_location
  resource_group_name = var.tikweb_rg_name
  service_plan_id     = var.tikweb_app_plan_id

  https_only = true

  site_config {
    ftps_state = "Disabled"
    always_on  = true

    application_stack {
      docker_image     = "docker.io/library/ghost"
      docker_image_tag = "5.38-alpine"
    }
  }

  storage_account {
    name         = "ghost-persistent-content-files"
    type         = "AzureFiles"
    account_name = var.storage_account_name
    access_key   = var.storage_account_key
    share_name   = var.storage_share_name
    mount_path   = "/var/lib/ghost/content"
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
    HOST = "0.0.0.0"
    PORT = 2368

    # GHOST CONFIGURATION
    url = var.ghost_front_url

    # Database
    database__client                              = "mysql"
    database__connection__host                    = var.mysql_fqdn
    database__connection__user                    = var.mysql_username
    database__connection__password                = var.mysql_password
    database__connection__database                = var.mysql_db_name
    database__connection__ssl__rejectUnauthorized = "true"
    database__connection__ssl__minVersion         = "TLSv1.2"

    # Email
    mail__transport           = "SMTP"
    mail__options__service    = "Mailgun"
    mail__options__host       = var.ghost_mail_host
    mail__options__port       = var.ghost_mail_port
    mail__options__secure     = "true"
    mail__options__auth__user = var.ghost_mail_username
    mail__options__auth__pass = var.ghost_mail_password
  }
}

resource "azurerm_app_service_custom_hostname_binding" "tikjob_hostname_binding" {
  hostname            = local.fqdn
  app_service_name    = azurerm_linux_web_app.tikjob_ghost.name
  resource_group_name = var.tikweb_rg_name

  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }

  # Deletion may need manual work.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/11231
  # TODO: Add dependencies for creation
  # depends_on = [
  #   azurerm_dns_a_record.tikjob_a,
  #   azurerm_dns_txt_record.tikjob_asuid
  # ]
}

resource "random_password" "tikjob_cert_password" {
  length  = 48
  special = false
}

resource "acme_certificate" "tikjob_acme_cert" {
  account_key_pem          = var.acme_account_key
  common_name              = local.fqdn
  key_type                 = "2048" # RSA
  certificate_p12_password = random_password.tikjob_cert_password.result

  dns_challenge {
    provider = "azure"
    config = {
      AZURE_RESOURCE_GROUP = var.dns_resource_group_name
      AZURE_ZONE_NAME      = var.root_zone_name
    }
  }
}

resource "azurerm_app_service_certificate" "tikjob_cert" {
  name                = "tikjob-cert"
  resource_group_name = var.tikweb_rg_name
  location            = var.tikweb_rg_location
  pfx_blob            = acme_certificate.tikjob_acme_cert.certificate_p12
  password            = acme_certificate.tikjob_acme_cert.certificate_p12_password
}

resource "azurerm_app_service_certificate_binding" "tikjob_cert_binding" {
  certificate_id      = azurerm_app_service_certificate.tikjob_cert.id
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.tikjob_hostname_binding.id
  ssl_state           = "SniEnabled"
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/14642#issuecomment-1084728235
# Currently, the azurerm provider doesn't give us the IP address, so we need to fetch it ourselves.
data "dns_a_record_set" "tikjob_dns_fetch" {
  host = azurerm_linux_web_app.tikjob_ghost.default_hostname
}
