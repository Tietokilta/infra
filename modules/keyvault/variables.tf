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
