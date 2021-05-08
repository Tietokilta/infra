resource "azurerm_postgresql_database" "tikweb_cms_db" {
  name                = "${var.env_name}cms_db"
  resource_group_name = var.resource_group_name
  server_name         = var.postgres_server_name
  charset             = "UTF8"
  collation           = "fi_FI"
}
