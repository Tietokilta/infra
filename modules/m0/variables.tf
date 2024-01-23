
variable "resource_group_location" {
  type = string
}
variable "smtp_password" {
  type      = string
  sensitive = true
}
variable "smtp_email" {
  type      = string
  sensitive = true
}

variable "mail_subdomain" {
  type = string
}
variable "mail_dns_resource_group_name" {
  type = string
}
variable "mail_dns_zone_name" {
  type = string
}
variable "dkim_selector" {
  type = string
}

variable "dkim_key" {
  type = string
}

variable "app_service_plan_id" {
  type = string
}

variable "web_resource_group_name" {
  type = string
}

variable "acme_account_key" {
  type = string
}
variable "postgres_server_fqdn" {
  type = string
}

variable "postgres_admin_password" {
  type      = string
  sensitive = true
}

variable "postgres_server_id" {
  type = string
}
variable "strapi_token" {
  type      = string
  sensitive = true
}
