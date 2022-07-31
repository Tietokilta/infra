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
  type = string
}

variable "strapi_jwt_secret" {
  type      = string
  sensitive = true
}

variable "strapi_admin_jwt_secret" {
  type      = string
  sensitive = true
}

variable "strapi_api_token_salt" {
  type      = string
  sensitive = true
}

variable "strapi_app_keys" {
  type      = string
  sensitive = true
}

variable "postgres_server_host" {
  type = string
}

variable "github_app_key" {
  type = string
}

variable "uploads_storage_account_name" {
  type = string
}

variable "uploads_storage_account_key" {
  type      = string
  sensitive = true
}

variable "uploads_container_name" {
  type = string
}
