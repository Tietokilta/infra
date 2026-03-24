variable "dns_resource_group_name" {
  type = string
}

variable "root_zone_name" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "dkim_selector" {
  type = string
}

variable "dkim_key" {
  type = string
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for tietokilta.fi."
  default     = ""
}
