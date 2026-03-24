variable "mailgun_api_key" {
  type      = string
  sensitive = true
}

variable "app_service_plan_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "dns_resource_group_name" {
  type = string
}

variable "root_zone_name" {
  type = string
}

variable "acme_account_key" {
  type = string
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for tietokilta.fi. Used for DNS records and ACME challenge."
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token for ACME DNS challenge."
  sensitive   = true
}
