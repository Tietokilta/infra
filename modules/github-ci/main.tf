data "azurerm_subscription" "primary" {
}

resource "azuread_application_registration" "github_oidc" {
  for_each = var.repo_app_service_map

  display_name = "github-actions-${replace(each.key, "/", "-")}"
}


resource "azuread_service_principal" "github_oidc" {
  for_each  = azuread_application_registration.github_oidc
  client_id = each.value.client_id
}

resource "azuread_application_federated_identity_credential" "github_oidc" {
  for_each       = azuread_application_registration.github_oidc
  application_id = each.value.id
  display_name   = "github-actions-${replace(each.key, "/", "-")}-federated-credential"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${each.key}:ref:refs/heads/main"
}


locals {
  flattened_role_assignments = flatten([
    for repo, app_services in var.repo_app_service_map :
    [
      for app_service in app_services :
      {
        repo        = repo
        app_service = app_service
      }
    ]
  ])
}

resource "azurerm_role_assignment" "github_oidc_role" {
  for_each = {
    for assignment in local.flattened_role_assignments :
    "${assignment.repo}-${replace(assignment.app_service, "/", "-")}" => assignment
  }

  scope = each.value.app_service
  # https://github.com/Azure/webapps-deploy?tab=readme-ov-file#configure-deployment-credentials-1
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_oidc[each.value.repo].object_id
}
