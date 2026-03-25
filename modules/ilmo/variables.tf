variable "environment" {
  type = string
}

variable "tikweb_rg_name" {
  type = string
}

variable "tikweb_rg_location" {
  type = string
}

variable "tikweb_app_plan_id" {
  type = string
}

variable "postgres_server_fqdn" {
  type = string
}

variable "postgres_server_id" {
  type = string
}

variable "edit_token_secret" {
  type      = string
  sensitive = true
}

variable "auth_jwt_secret" {
  type      = string
  sensitive = true
}

variable "mailgun_api_key" {
  type      = string
  sensitive = true
}

variable "website_url" {
  type = string
}


variable "root_zone_name" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "acme_account_key" {
  type = string
}

variable "stripe_secret_key" {
  type      = string
  sensitive = true
}

variable "stripe_webhook_secret" {
  type      = string
  sensitive = true
}

variable "extra_frontends" {
  type = map(object({
    eventDetailsUrl    = optional(string)
    editSignupUrl      = optional(string)
    completePaymentUrl = optional(string)
    adminUrl           = optional(string)
  }))
  default = {}
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
