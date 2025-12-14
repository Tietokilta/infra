variable "env_name" {
  type = string
}

variable "postgres_resource_group_name" {
  type = string
}

variable "resource_group_location" {
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

variable "tikweb_app_plan_id" {
  type = string
}

variable "tikweb_app_plan_rg_name" {
  type = string
}

variable "tikweb_app_plan_rg_location" {
  type = string
}

variable "django_secret_key" {
  type      = string
  sensitive = true
}

variable "acme_account_key" {
  type      = string
  sensitive = true
}

variable "dns_resource_group_name" {
  type = string
}

variable "root_zone_name" {
  type = string
}
