variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "postgres_server_fqdn" {
  type = string
}

variable "postgres_server_id" {
  type = string
}


variable "root_zone_name" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "tikweb_app_plan_id" {
  type = string
}

variable "tikweb_rg_name" {
  type = string
}

variable "tikweb_rg_location" {
  type = string
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for tietokilta.fi, for the old.tietokilta.fi records."
}

variable "ghcr_token" {
  type      = string
  sensitive = true
}
