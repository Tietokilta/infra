variable "repository" {
  description = "The GitHub repository in the format 'owner/repo'."
  type        = string
}

variable "app_service_ids" {
  description = "A list of Azure App Service resource IDs to grant Contributor access to."
  type        = list(string)
}
