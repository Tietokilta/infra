data "azurerm_subscription" "primary" {}

module "role" {
  source   = "../github-ci-role"
  for_each = var.repo_app_service_map

  repository = each.key
  role_assignments = [
    for id in each.value : {
      scope                = id
      role_definition_name = "Contributor"
    }
  ]
}
