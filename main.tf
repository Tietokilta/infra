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
  source                  = "./modules/common"
  env_name                = terraform.workspace
  postgres_admin_password = var.postgres_admin_password
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
  postgres_admin_password = var.postgres_admin_password
  strapi_admin_jwt_secret = var.strapi_admin_jwt_secret
}
