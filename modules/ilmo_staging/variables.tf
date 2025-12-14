variable "environment" {
  type = string
}

variable "tikweb_rg_name" {
  type = string
}

variable "tikweb_rg_location" {
  type = string
}

variable "tikweb_app_plan_id" {
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

variable "website_url" {
  type = string
}
