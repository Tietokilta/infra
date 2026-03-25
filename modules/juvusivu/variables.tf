variable "app_service_plan_id" {
  type = string
}
variable "app_service_plan_resource_group_name" {
  description = "Resource group of the existing App Service Plan"
  type        = string
}

variable "app_service_plan_location" {
  description = "Location of the existing App Service Plan"
  type        = string
}
variable "environment" {
  type = string
}
variable "location" {
  type = string
}


// Postgres
variable "postgres_server_fqdn" {
  type = string
}

variable "postgres_server_id" {
  type = string
}

// DNS
variable "acme_account_key" {
  type      = string
  sensitive = true
}


variable "root_zone_name" {
  type = string
}

variable "m0_dns_zone_name" {
  type = string
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for juhlavuosi.fi."
}

variable "cloudflare_m0_zone_id" {
  type        = string
  description = "Cloudflare zone ID for muistinnollaus.fi."
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token for ACME DNS challenge."
  sensitive   = true
}
