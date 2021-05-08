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

locals {
  env_prefix = "prod"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "tikweb_rg" {
  name     = "tikWebResourceGroup"
  location = "northeurope"
}

resource "azurerm_storage_account" "tikweb_sa" {
  name                      = "${local.env_prefix}tikwebsa"
  resource_group_name       = azurerm_resource_group.tikweb_rg.name
  location                  = azurerm_resource_group.tikweb_rg.location
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  enable_https_traffic_only = true
  allow_blob_public_access  = true

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }
}

resource "azurerm_storage_container" "frontend_container" {
  name                  = "${local.env_prefix}frontendcontainer"
  storage_account_name  = azurerm_storage_account.tikweb_sa.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.tikweb_sa.name
  storage_container_name = azurerm_storage_container.frontend_container.name
  type                   = "Block"
  content_type           = "text/html"
  source                 = "index.html"
}
