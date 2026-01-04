
resource "azurerm_resource_group" "rg" {
  name     = "vaultwarden-rg"
  location = var.location
}
# Storage Account and File Share
resource "azurerm_storage_account" "storage_account" {
  name                     = "tikvaultwardenstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Zone redundant https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_share" "file_share" {
  name               = "vaultwarden-data"
  storage_account_id = azurerm_storage_account.storage_account.id
  quota              = 10 # GB
}

# App Service (Linux Web App)
resource "azurerm_linux_web_app" "vaultwarden_app" {
  name                = "tik-vaultwarden-${var.environment}"
  location            = var.location
  resource_group_name = var.app_service_plan_resource_group_name
  service_plan_id     = var.app_service_plan_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    ftps_state = "Disabled"
    always_on  = false

    application_stack {
      docker_registry_url = "https://docker.io"
      docker_image_name   = "vaultwarden/server:latest"
    }
  }
  # Mount the Azure File Share
  storage_account {
    name         = "vaultwarden-persistent-storage"
    account_name = azurerm_storage_account.storage_account.name
    access_key   = azurerm_storage_account.storage_account.primary_access_key
    mount_path   = "/data"
    share_name   = azurerm_storage_share.file_share.name
    type         = "AzureFiles"
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                       = "80"

    # Vaultwarden Environment Variables
    ADMIN_TOKEN     = var.admin_api_key
    DOMAIN          = "https://${local.fqdn}"
    SIGNUPS_ALLOWED = "false"

    # SMTP configuration 
    SMTP_SECURITY = "force_tls"
    SMTP_HOST     = var.smtp_host
    SMTP_FROM     = var.vaultwarden_smtp_from
    SMTP_PORT     = 465
    SMTP_USERNAME = var.vaultwarden_smtp_username
    SMTP_PASSWORD = var.vaultwarden_smtp_password
    # Database configuration
    DATABASE_URL = "postgresql://${var.db_username}:${var.db_password}@${var.db_host}:${var.db_port}/${var.db_name}"
  }
}

module "vaultwarden_hostname" {
  source = "../app_service_hostname"

  subdomain                       = var.subdomain
  root_zone_name                  = var.root_zone_name
  dns_resource_group_name         = var.dns_resource_group_name
  custom_domain_verification_id   = azurerm_linux_web_app.vaultwarden_app.custom_domain_verification_id
  app_service_name                = azurerm_linux_web_app.vaultwarden_app.name
  app_service_resource_group_name = var.app_service_plan_resource_group_name
  app_service_location            = var.location
  app_service_default_hostname    = azurerm_linux_web_app.vaultwarden_app.default_hostname
  acme_account_key                = var.acme_account_key
  certificate_name                = "tik-vaultwarden-cert-${var.environment}"
}
