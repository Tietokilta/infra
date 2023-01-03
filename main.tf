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

module "common" {
  source   = "./modules/common"
  env_name = terraform.workspace
}

module "frontend" {
  source                  = "./modules/frontend"
  env_name                = "prod"
  resource_group_name     = module.common.resource_group_name
  resource_group_location = module.common.resource_group_location
}

module "frontend_staging" {
  source                  = "./modules/frontend"
  env_name                = "staging"
  resource_group_name     = module.common.resource_group_name
  resource_group_location = module.common.resource_group_location
}

module "cms" {
  source                       = "./modules/cms"
  env_name                     = terraform.workspace
  resource_group_name          = module.common.resource_group_name
  resource_group_location      = module.common.resource_group_location
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
  env_name                = terraform.workspace
  resource_group_name     = module.common.resource_group_name
  resource_group_location = module.common.resource_group_location
  postgres_server_name    = module.common.postgres_server_name
  postgres_server_fqdn    = module.common.postgres_server_fqdn
  postgres_server_host    = module.common.postgres_server_host
  postgres_admin_password = module.common.postgres_admin_password
  edit_token_secret       = var.ilmo_edit_token_secret
  auth_jwt_secret         = var.ilmo_auth_jwt_secret
  mailgun_api_key         = var.ilmo_mailgun_api_key
  mailgun_domain          = var.ilmo_mailgun_domain
  website_events_url      = "https://${module.frontend.fqdn}/tapahtumat"
}

module "histotik" {
  source                  = "./modules/histotik"
  env_name                = terraform.workspace
  resource_group_location = module.common.resource_group_location
}

module "tenttiarkisto" {
  source                       = "./modules/tenttiarkisto"
  env_name                     = terraform.workspace
  postgres_resource_group_name = module.common.resource_group_name
  resource_group_location      = module.common.resource_group_location
  postgres_server_name         = module.common.postgres_server_name
  postgres_server_fqdn         = module.common.postgres_server_fqdn
  postgres_server_host         = module.common.postgres_server_host
  postgres_admin_password      = module.common.postgres_admin_password
  aux_app_plan_id              = module.common.aux_app_plan_id
  django_secret_key            = var.tenttiarkisto_django_secret_key
}

module "voo" {
  source                  = "./modules/voo"
  env_name                = terraform.workspace
  resource_group_location = "northeurope"
}

module "tikjob_storage" {
  source                  = "./modules/recruiting/storage"
  env_name                = terraform.workspace
  resource_group_location = "northeurope"
  ghost_db_username       = "tikrekryadmin"
}

module "tikjob_app" {
  source = "./modules/recruiting/ghost"

  env_name                = terraform.workspace
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

  ghost_hostname = "rekry.tietokilta.fi"

  cert_password = var.tikjob_cert_password
}

module "forum" {
  source                  = "./modules/forum"
  env_name                = terraform.workspace
  resource_group_location = "northeurope"
}
