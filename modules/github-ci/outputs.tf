# Output Azure Client IDs for Each Repository
output "azure_client_ids" {
  description = "Mapping of GitHub repositories to their Azure AD Application Client IDs."
  value = {
    for repo, app in azuread_application_registration.github_oidc :
    repo => app.client_id
  }
}

# Output Azure Subscription ID
output "azure_subscription_id" {
  description = "Azure Subscription ID."
  value       = data.azurerm_subscription.primary.subscription_id
}

# Output Azure Tenant ID
output "azure_tenant_id" {
  description = "Azure Tenant ID."
  value       = data.azurerm_subscription.primary.tenant_id
}
