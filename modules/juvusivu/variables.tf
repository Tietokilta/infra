variable "app_service_plan_id" {
  type = string
}
variable "app_service_plan_resource_group_name" {
  description = "Resource group of the existing App Service Plan"
  type        = string
}

variable "app_service_plan_location" {
  description = "Location of the existing App Service Plan"
  type        = string
}
variable "environment" {
  type = string
}
variable "location" {
  type = string
}


// Postgres
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

// DNS
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
