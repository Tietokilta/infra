variable "env_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "postgres_server_name" {
  type = string
}

variable "postgres_server_fqdn" {
  type = string
}

variable "postgres_admin_password" {
  type      = string
  sensitive = true
}

variable "postgres_server_host" {
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
