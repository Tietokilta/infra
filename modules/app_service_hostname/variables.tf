
variable "subdomain" {
  type        = string
  description = "The subdomain for the app service."
}

variable "root_zone_name" {
  type        = string
  description = "The root zone name for the DNS records."
}

variable "dns_resource_group_name" {
  type        = string
  description = "The resource group name for the DNS zone."
}

variable "custom_domain_verification_id" {
  type        = string
  description = "The custom domain verification ID for the app service."
}

variable "app_service_name" {
  type        = string
  description = "The name of the app service."
}

variable "app_service_resource_group_name" {
  type        = string
  description = "The resource group name for the app service."
}

variable "app_service_location" {
  type        = string
  description = "The location of the app service."
}

variable "app_service_default_hostname" {
  type        = string
  description = "The default hostname of the app service."
}

variable "acme_account_key" {
  type        = string
  description = "The ACME account key."
  sensitive   = true
}

variable "certificate_name" {
  type        = string
  description = "The name of the certificate resource."
}
