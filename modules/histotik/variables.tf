variable "env_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "root_zone_name" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for tietokilta.fi."
}
