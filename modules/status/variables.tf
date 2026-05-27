variable "subdomain" {
  type = string
}
variable "root_zone_name" {
  type = string
}
variable "acme_account_key" {
  type = string
}
variable "location" {
  description = "Azure location"
  type        = string
}

variable "app_service_plan_id" {
  description = "ID of the existing App Service Plan"
  type        = string
}

variable "app_service_plan_resource_group_name" {
  description = "Resource group of the existing App Service Plan"
  type        = string
}

variable "app_service_plan_location" {
  description = "Location of the existing App Service Plan"
  type        = string
}

variable "telegram_token" {
  description = "Telegram bot API token"
  type        = string
}

variable "telegram_channel_id" {
  description = "Telegram alert channel id"
  type        = string
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
