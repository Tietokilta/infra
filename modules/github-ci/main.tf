data "azurerm_subscription" "primary" {}

module "role" {
  source   = "../github-ci-role"
  for_each = var.repo_app_service_map

  repository      = each.key
  app_service_ids = each.value
}

