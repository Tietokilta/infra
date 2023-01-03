terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.99.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.2.3"
    }
  }
  backend "azurerm" {
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    resource_group_name  = "terraform-state"
    storage_account_name = "tikprodterraform"
  }
}

provider "azurerm" {
  features {}
}

provider "dns" {
}

locals {
  resource_group_location = "northeurope"
}

module "dns_prod" {
  source                  = "./modules/dns/root"
  env_name                = "prod"
  resource_group_location = local.resource_group_location
  zone_name               = "tietokilta.fi"
}

module "dns_staging" {
  source                  = "./modules/dns/root"
  env_name                = "staging"
  resource_group_location = local.resource_group_location
  zone_name               = "tietokila.fi"
}

module "mailman" {
  source = "./modules/dns/mailman"

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.zone_name
  subdomain               = "list"

  dkim_selector = "mta"
  dkim_key = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDJN6WyS7YQcOKO4MKsSbrYfjL8hh24ot/0uQysHte3eqscbbwCFVlgmsg3423by3e20ZSBMhRXdtIkYdgn8wkfPyZlHVEOvOJBCR+tKqtexxQEbkk8LqmEzVggNZoLLX06wYNqt2Nxl++dlvUuB4IxmPPGQed3Xr7HBT8OZmKJYQIDAQAB"
}

module "dns_misc_prod" {
  source = "./modules/dns/prod"
  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.zone_name
}

module "common" {
  source                  = "./modules/common"
  env_name                = "prod"
  resource_group_location = local.resource_group_location
}

module "frontend" {
  source                  = "./modules/frontend"
  env_name                = "prod"
  resource_group_name     = module.common.resource_group_name
  resource_group_location = local.resource_group_location
}

module "frontend_staging" {
  source                  = "./modules/frontend"
  env_name                = "staging"
  resource_group_name     = module.common.resource_group_name
  resource_group_location = local.resource_group_location
}

module "cms" {
  source                       = "./modules/cms"
  env_name                     = "prod"
  resource_group_name          = module.common.resource_group_name
  resource_group_location      = local.resource_group_location
  postgres_server_name         = module.common.postgres_server_name
  postgres_server_fqdn         = module.common.postgres_server_fqdn
  postgres_server_host         = module.common.postgres_server_host
  postgres_admin_password      = module.common.postgres_admin_password
  strapi_jwt_secret            = var.strapi_jwt_secret
  strapi_admin_jwt_secret      = var.strapi_admin_jwt_secret
  strapi_api_token_salt        = var.strapi_api_token_salt
  strapi_app_keys              = var.strapi_app_keys
  github_app_key               = var.github_app_key
  uploads_storage_account_name = module.frontend.storage_account_name
  uploads_storage_account_key  = module.frontend.storage_account_key
  uploads_container_name       = module.frontend.uploads_container_name
}

module "ilmo" {
  source                  = "./modules/ilmo"
  env_name                = "prod"
  resource_group_name     = module.common.resource_group_name
  resource_group_location = local.resource_group_location
  postgres_server_name    = module.common.postgres_server_name
  postgres_server_fqdn    = module.common.postgres_server_fqdn
  postgres_server_host    = module.common.postgres_server_host
  postgres_admin_password = module.common.postgres_admin_password
  edit_token_secret       = var.ilmo_edit_token_secret
  auth_jwt_secret         = var.ilmo_auth_jwt_secret
  mailgun_api_key         = var.ilmo_mailgun_api_key
  mailgun_domain          = var.ilmo_mailgun_domain
  website_events_url      = "https://${module.frontend.fqdn}/tapahtumat"

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.zone_name
  subdomain               = "ilmo"

  dkim_selector = "mg"
  dkim_key      = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDQYrVWefo+vOByb07hseOTt1Ryu47Yt5odumYka5JiEt1p/FHl/ZeeY8gehxV0Dv4PIWM91htY2JY2UZguGYFODzqq9Y9AeKjWpq1dyFKiM8nlrI6GRin0kY7SRLeSgpcVFuwNLiT74Wqy477Geq+l5/Stwho23kHu/pXiQuVUMwIDAQAB"
}

module "histotik" {
  source                  = "./modules/histotik"
  env_name                = "prod"
  resource_group_location = local.resource_group_location

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.zone_name
  subdomain               = "histotik"
}

module "tenttiarkisto" {
  source                       = "./modules/tenttiarkisto"
  env_name                     = "prod"
  postgres_resource_group_name = module.common.resource_group_name
  resource_group_location      = local.resource_group_location
  postgres_server_name         = module.common.postgres_server_name
  postgres_server_fqdn         = module.common.postgres_server_fqdn
  postgres_server_host         = module.common.postgres_server_host
  postgres_admin_password      = module.common.postgres_admin_password
  aux_app_plan_id              = module.common.aux_app_plan_id
  django_secret_key            = var.tenttiarkisto_django_secret_key
}

module "voo" {
  source                  = "./modules/voo"
  env_name                = "prod"
  resource_group_location = local.resource_group_location
}

module "tikjob_storage" {
  source                  = "./modules/recruiting/storage"
  env_name                = "prod"
  resource_group_location = local.resource_group_location
  ghost_db_username       = "tikrekryadmin"
}

module "tikjob_app" {
  source = "./modules/recruiting/ghost"

  env_name                = "prod"
  resource_group_name     = module.tikjob_storage.resource_group_name
  resource_group_location = module.tikjob_storage.resource_group_location
  ghost_front_url         = "https://rekry.tietokilta.fi"

  mysql_db_name  = module.tikjob_storage.mysql_db_name
  mysql_fqdn     = module.tikjob_storage.mysql_fqdn
  mysql_username = module.tikjob_storage.mysql_username
  mysql_password = module.tikjob_storage.mysql_password

  storage_account_name = module.tikjob_storage.storage_account_name
  storage_account_key  = module.tikjob_storage.storage_account_key
  storage_share_name   = module.tikjob_storage.storage_share_name

  ghost_mail_host     = "smtp.eu.mailgun.org"
  ghost_mail_port     = 465
  ghost_mail_username = var.tikjob_ghost_mail_username
  ghost_mail_password = var.tikjob_ghost_mail_password

  cert_password = var.tikjob_cert_password

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.zone_name
  subdomain               = "rekry"

  dkim_selector = "mta"
  dkim_key      = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDYQLHt0gzozEScD5nNockttK0D0r6MejAOgMBj0e++DtDev9OvTJru5ZtKFlLGXxf3b7GWvV10X5kCT0D2HD/vDfaokZ+EL58lRWg7qlz10XBN/7XDTgPDbDuCBC3mH9W8DeI38omNCT+8fgzVvCjHUfYlvf3dMOn4Ow7zeAZ5yQIDAQAB"
}

module "forum" {
  source   = "./modules/forum"
  env_name = "prod"

  resource_group_location = local.resource_group_location

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.zone_name
  subdomain               = "vaalit"

  dkim_selector = "krs"
  dkim_key      = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDS4SY1m4JfklDMhdIQIVx+k2EHfagB+67WpX5/2YtUjw5By3l7C7skgXvO8XfaANwBpE4TWvV2V1qbYiMfGGMzDnoi7KWb4sFqd6zQGqjEKV2HEysihh0LmKSCCKLnKfPB2nTeSQu2ZSmnGBcKSeCCx9WwPEkGyvpB/1RaiqEy2wIDAQAB"
}

module "mattermost" {
  source = "./modules/mattermost"

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.zone_name
  subdomain               = "mm"

  dkim_selector = "email"
  dkim_key      = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDEIS79WkHcT6Dr1KLQp9CkLtzCqU/We4SqYWSQSQkfabOdWyoKkQJlwjLzbMjLSQtX35gPvSQXIzqYnC0dhppQoNleu25Me0QIfjwc7cWSvYUC1HEp1OX5+NTZXHvCuc0KdhEEQ3tUTUnSAk7QZZMUlX+gSQV5MFMEO9Wcqk4E1wIDAQAB"

  mattermost_ip = module.forum.forum_ip
}

module "invoicing" {
  source   = "./modules/invoicing"
  env_name = "prod"

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.zone_name
  subdomain               = "laskutus"

  dkim_selector = "mta"
  dkim_key      = "k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsAjLp5HRzTjMcjGGjZ75U42hCUaopuficYZiyLL3Ail/BmTqh2K8LRxN2UrWXOzVGLEh2F9PR6MC7nqR1Vj+3yR4+5nznwfmZh0cnX4Q2asm7A76st4uVwkVk0y21Mj1wufBIz885XCk+rzeorMOCU+lDZUIehYk1sVSDcubDuBAwJ9TBLXj2EMmcrD1KmJWMca0d5I6RfB+ZD7hG97rWhpgPuKYP7gaT6/t+ekXIJn9ZJmNRoIm/5X04AdM20ywwUrVe6NzWkB8eFuVy01DZki2bI9JnPwjnjw+KgZWrZBhtaYE8umVExmwGmI9PTzrHrknaBKQ0UBrDqSlyXuWgwIDAQAB"
}
