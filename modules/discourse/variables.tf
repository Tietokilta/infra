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

variable "discourse_ip" {
  type = string
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for tietokilta.fi."
}
