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

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for tietokilta.fi, for the old.tietokilta.fi records."
}
