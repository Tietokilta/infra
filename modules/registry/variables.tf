variable "postgres_server_id" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "app_service_plan_id" {
  type = string
}

variable "postgres_server_fqdn" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "root_zone_name" {
  type = string
}

variable "dns_resource_group_name" {
  type = string
}

variable "acme_account_key" {
  type = string
}

variable "environment" {
  type = string
}

variable "mailgun_api_key" {
  type      = string
  sensitive = true
}

variable "stripe_api_key" {
  type      = string
  sensitive = true
}

variable "stripe_webhook_secret" {
  type      = string
  sensitive = true
}
