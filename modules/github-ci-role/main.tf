resource "azuread_application_registration" "github_oidc" {
  display_name = "github-actions-${replace(var.repository, "/", "-")}"
}

resource "azuread_service_principal" "github_oidc" {
  client_id = azuread_application_registration.github_oidc.client_id
}

resource "azuread_application_federated_identity_credential" "github_oidc" {
  application_id = azuread_application_registration.github_oidc.id
  display_name   = "github-actions-${replace(var.repository, "/", "-")}-federated-credential"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.repository}:ref:refs/heads/main"
}

resource "azurerm_role_assignment" "github_oidc_role" {
  count = length(var.app_service_ids)

  scope                = var.app_service_ids[count.index]
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_oidc.object_id
}
