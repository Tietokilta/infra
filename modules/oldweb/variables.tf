variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "postgres_server_fqdn" {
  type = string
}

variable "postgres_admin_password" {
  type      = string
  sensitive = true
}

variable "postgres_admin_username" {
  type = string
}

variable "postgres_server_id" {
  type = string
}

variable "dns_resource_group_name" {
  type = string
}

variable "root_zone_name" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "tikweb_app_plan_id" {
  type = string
}

variable "tikweb_rg_name" {
  type = string
}

variable "tikweb_rg_location" {
  type = string
}

variable "acme_account_key" {
  type = string
}
