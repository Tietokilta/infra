output "client_id" {
  description = "The Client ID of the Azure AD application."
  value       = azuread_application_registration.github_oidc.client_id
}
