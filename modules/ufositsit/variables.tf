variable "environment" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "app_service_plan_id" {
  type = string
}

variable "postgres_server_id" {
  type = string
}

variable "postgres_server_fqdn" {
  type = string
}

variable "root_zone_name" {
  type = string
}

variable "acme_account_key" {
  type      = string
  sensitive = true
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for ufosits.it. Used for DNS records and ACME challenge."
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token for ACME DNS challenge."
  sensitive   = true
}

variable "ghcr_token" {
  type      = string
  sensitive = true
}

// Event
variable "event_start" {
  type        = string
  description = "ISO-8601 datetime"
}

variable "registration_start" {
  type        = string
  description = "ISO-8601 datetime"
}

variable "registration_end" {
  type        = string
  description = "ISO-8601 datetime"
}

variable "payment_due_date" {
  type        = string
  description = "ISO-8601 date"
}

variable "max_participants" {
  type = number
}

variable "participation_fee_cents" {
  type = number
}

variable "contact_telegram" {
  type        = string
  description = "Organizer's Telegram handle, without the @"
  sensitive   = true
}

variable "mobilepay_number" {
  type        = string
  description = "MobilePay number participants pay to"
  sensitive   = true
}
