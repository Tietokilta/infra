variable "mailgun_api_key" {
  type      = string
  sensitive = true
}

variable "mailgun_url" {
  type = string
}

variable "mailgun_user" {
  type = string
}

variable "app_service_plan_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "dns_resource_group_name" {
  type = string
}

variable "root_zone_name" {
  type = string
}

variable "acme_account_key" {
  type = string
}

variable "dkim_selector" {
  type = string
}

variable "dkim_key" {
  type = string
}
