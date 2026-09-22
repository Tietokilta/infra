variable "root_zone_name" {
  type = string
}

variable "subdomains" {
  type        = set(string)
  description = "Subdomains of the root zone that resolve to tikpannu."
}

variable "tikpannu_ip" {
  type = string
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for tietokilta.fi."
}
