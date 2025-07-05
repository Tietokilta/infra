variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

// Certs

variable "acme_account_key" {
  type      = string
  sensitive = true
}

variable "dns_resource_group_name" {
  type = string
}
variable "subdomain" {
  type = string
}

variable "root_zone_name" {
  type = string
}


variable "app_service_plan_id" {
  type = string
}
variable "mongo_connection_string" {
  type      = string
  sensitive = true
}
variable "google_oauth_client_id" {
  type      = string
  sensitive = true
}
variable "google_oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "public_ilmo_url" {
  type = string
}

variable "public_laskugeneraattori_url" {
  type = string
}

variable "public_legacy_url" {
  type = string
}

variable "digitransit_subscription_key" {
  type      = string
  sensitive = true
}

variable "mailgun_sender" {
  type      = string
  sensitive = true
}

variable "mailgun_receiver" {
  type      = string
  sensitive = true
}

variable "mailgun_api_key" {
  type      = string
  sensitive = true
}

variable "mailgun_domain" {
  type      = string
  sensitive = true
}

variable "mailgun_url" {
  type      = string
  sensitive = true
}
variable "environment" {
  type = string
}
