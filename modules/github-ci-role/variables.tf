variable "repository" {
  description = "The GitHub repository in the format 'owner/repo'."
  type        = string
}

variable "subject" {
  description = "The subject claim for the federated identity credential. Defaults to 'repo:{repository}:ref:refs/heads/main'."
  type        = string
  default     = null
}

variable "role_assignments" {
  description = "List of role assignments to create for the service principal."
  type = list(object({
    scope                = string
    role_definition_name = string
  }))
  default = []
}
