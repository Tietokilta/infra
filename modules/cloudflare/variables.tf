variable "zone_id" {
  type        = string
  description = "The Cloudflare zone ID for tietokilta.fi"
}

variable "github_challenge_value" {
  type        = string
  description = "The GitHub organization challenge TXT record value"
  sensitive   = true
}

variable "dmarc_report_domains" {
  type        = set(string)
  description = "Set of FQDNs authorized to receive DMARC reports for the root domain"
}

variable "full_ssl_hosts" {
  type        = set(string)
  description = "Hosts whose origin certificate does not match their name, so Cloudflare must use \"full\" instead of \"strict\" SSL"
}
