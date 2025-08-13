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

variable "postgres_admin_username" {
  type = string
}

variable "postgres_admin_password" {
  type      = string
  sensitive = true
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
