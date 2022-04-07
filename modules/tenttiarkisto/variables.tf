variable "env_name" {
  type = string
}

variable "postgres_resource_group_name" {
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

variable "django_secret_key" {
  type      = string
  sensitive = true
}
