variable "env_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}
variable "keyvault_secrets" {
  type        = list(string)
  description = "list of secrets that are expected to be present in the keyvault."
}

variable "managed_identity_principals" {
  type = map(object({
    principal_id = string
    tenant_id    = string
  }))
  description = "Map of managed identities that need access to Key Vault secrets. Key is a descriptive name, value contains principal_id and tenant_id."
  default     = {}
}
