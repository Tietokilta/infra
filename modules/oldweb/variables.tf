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


variable "root_zone_name" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "location" {
  description = "Azure location"
  type        = string
}
