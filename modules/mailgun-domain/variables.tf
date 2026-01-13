variable "domain_name" {
  description = "Full domain name (e.g., ilmo.tietokilta.fi)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain part for DNS records (e.g., ilmo)"
  type        = string
}

variable "dns_resource_group_name" {
  type = string
}

variable "dns_zone_name" {
  description = "Root DNS zone (e.g., tietokilta.fi)"
  type        = string
}

variable "create_smtp_credential" {
  description = "Whether to create SMTP credentials"
  type        = bool
  default     = false
}

variable "smtp_login" {
  description = "SMTP login username (without domain)"
  type        = string
  default     = "postmaster"
}

variable "dmarc_email" {
  description = "Email for DMARC reports"
  type        = string
  default     = "dmarc@tietokilta.fi"
}

variable "create_spf" {
  description = "Whether to create SPF TXT record (disable if service has combined TXT records)"
  type        = bool
  default     = true
}
