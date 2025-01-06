variable "repo_app_service_map" {
  description = <<EOT
  Mapping of GitHub repositories to a list of Azure App Service resource IDs.
  Format: {
    \"owner/repo1\" = [
      \"/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Web/sites/<app_service1>\",
      \"/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Web/sites/<app_service2>\"
    ],
    \"owner/repo2\" = [
      \"/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Web/sites/<app_service3>\"
    ]
  EOT
  type        = map(list(string))
}


#variable "azure_tenant_id" {
#  description = "The Tenant ID for Azure Active Directory."
#  type        = string
#}
