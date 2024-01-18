resource "azurerm_cosmosdb_account" "db_account" {
  name                = "tikweb-cosmosdb-${terraform.workspace}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "MongoDB"
  enable_free_tier    = true
  capabilities {
    name = "EnableMongo"
  }
  public_network_access_enabled = false
  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.resource_group_location
    failover_priority = 0
  }
  virtual_network_rule {
    id = var.private_subnet_id
  }
  capacity {
    # CosmosDB free tier allows for a throughput of 1000 at max
    total_throughput_limit = 1000
  }
  backup {
    retention_in_hours  = 168
    interval_in_minutes = 1440
    type                = "Periodic"
  }
}

resource "azurerm_cosmosdb_mongo_database" "db" {
  name                = "cms-${terraform.workspace}"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.db_account.name
  autoscale_settings {
    # CosmosDB free tier allows for a throughput of 1000 at max
    max_throughput = 1000
  }
}

resource "azurerm_storage_account" "tikweb_storage_account" {
  name                            = "tikweb${terraform.workspace}sa"
  resource_group_name             = var.resource_group_name
  location                        = var.resource_group_location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  min_tls_version                 = "TLS1_2"
  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [var.private_subnet_id]
  }
}

resource "azurerm_storage_container" "tikweb_media" {
  name                  = "media-${terraform.workspace}"
  storage_account_name  = azurerm_storage_account.tikweb_storage_account.name
  container_access_type = "private"
}
