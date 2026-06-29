variable "environment" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "app_service_plan_id" {
  type = string
}

variable "postgres_server_fqdn" {
  type = string
}

variable "postgres_server_id" {
  type = string
}

variable "acme_account_key" {
  type      = string
  sensitive = true
}

variable "root_zone_name" {
  type = string
}

variable "cloudflare_zone_id" {
  type = string
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "sisu_course_api_key" {
  type      = string
  sensitive = true
}

variable "get_all_secret" {
  type      = string
  sensitive = true
}
