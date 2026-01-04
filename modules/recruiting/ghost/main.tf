resource "azurerm_linux_web_app" "tikjob_ghost" {
  name                = "tikjob-${var.environment}-app-ghost"
  location            = var.tikweb_rg_location
  resource_group_name = var.tikweb_rg_name
  service_plan_id     = var.tikweb_app_plan_id

  identity {
    type = "SystemAssigned"
  }

  https_only = true

  site_config {
    ftps_state = "Disabled"
    always_on  = true

    application_stack {
      docker_registry_url = "https://docker.io"
      docker_image_name   = "ghost:5.109-alpine"
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
    url = "https://${module.tikjob_hostname.fqdn}"

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

module "tikjob_hostname" {
  source = "../../app_service_hostname"

  subdomain                       = var.subdomain
  root_zone_name                  = var.root_zone_name
  dns_resource_group_name         = var.dns_resource_group_name
  custom_domain_verification_id   = azurerm_linux_web_app.tikjob_ghost.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.tikjob_ghost.name
  app_service_resource_group_name = var.tikweb_rg_name
  app_service_location            = var.tikweb_rg_location
  app_service_default_hostname    = azurerm_linux_web_app.tikjob_ghost.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "tikjob-cert"
}
