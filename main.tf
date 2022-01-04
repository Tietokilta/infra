terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.57.0"
    }
  }
  backend "azurerm" {
    container_name = "tfstate"
    key            = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

module "common" {
  source   = "./modules/common"
  env_name = terraform.workspace
}

module "frontend" {
  source                  = "./modules/frontend"
  env_name                = terraform.workspace
  resource_group_name     = module.common.resource_group_name
  resource_group_location = module.common.resource_group_location
}

module "cms" {
  source                  = "./modules/cms"
  env_name                = terraform.workspace
  resource_group_name     = module.common.resource_group_name
  resource_group_location = module.common.resource_group_location
  postgres_server_name    = module.common.postgres_server_name
  postgres_server_fqdn    = module.common.postgres_server_fqdn
  postgres_server_host    = module.common.postgres_server_host
  postgres_admin_password = module.common.postgres_admin_password
  strapi_admin_jwt_secret = var.strapi_admin_jwt_secret
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
  ghost_mail_username = var.ghost_mail_username
  ghost_mail_password = var.ghost_mail_password
}
