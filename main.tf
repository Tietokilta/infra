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
