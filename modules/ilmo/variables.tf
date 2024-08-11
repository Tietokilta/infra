variable "env_name" {
  type = string
}

variable "resource_group_name" {
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

variable "postgres_server_id" {
  type = string
}

variable "edit_token_secret" {
  type      = string
  sensitive = true
}

variable "auth_jwt_secret" {
  type      = string
  sensitive = true
}

variable "mailgun_api_key" {
  type      = string
  sensitive = true
}

variable "mailgun_domain" {
  type = string
}

variable "website_events_url" {
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

variable "dkim_selector" {
  type = string
}

variable "dkim_key" {
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
