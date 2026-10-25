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
// App Service stores date-like app settings in UTC, so the datetimes must be given in UTC to not show as changed on
// every plan
variable "event_start" {
  type        = string
  description = "ISO-8601 datetime in UTC, for example 2026-11-12T16:00:00+00:00"
  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\+00:00$", var.event_start))
    error_message = "Use UTC in the form YYYY-MM-DDThh:mm:ss+00:00."
  }
}

variable "registration_start" {
  type        = string
  description = "ISO-8601 datetime in UTC, for example 2026-10-27T10:00:00+00:00"
  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\+00:00$", var.registration_start))
    error_message = "Use UTC in the form YYYY-MM-DDThh:mm:ss+00:00."
  }
}

variable "registration_end" {
  type        = string
  description = "ISO-8601 datetime in UTC, for example 2026-11-10T21:59:00+00:00"
  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\+00:00$", var.registration_end))
    error_message = "Use UTC in the form YYYY-MM-DDThh:mm:ss+00:00."
  }
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
