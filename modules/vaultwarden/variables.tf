variable "admin_api_key" {
  description = "Vaultwarden Admin API key used to access /admin page - minLength is 20"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.admin_api_key) >= 20
    error_message = "Admin API Key must be at least 20 characters."
  }
}
variable "subdomain" {
  type = string
}
variable "root_zone_name" {
  type = string
}
variable "dns_resource_group_name" {
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
variable "db_host" {
  description = "Hostname or IP address of the existing PostgreSQL database"
  type        = string
}

variable "db_port" {
  description = "Port number of the existing PostgreSQL database"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Name of the existing PostgreSQL database"
  type        = string
}

variable "db_username" {
  description = "Username for the existing PostgreSQL database"
  type        = string
}

variable "db_password" {
  description = "Password for the existing PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "app_service_plan_id" {
  description = "ID of the existing App Service Plan"
  type        = string
}

variable "app_service_plan_resource_group_name" {
  description = "Resource group of the existing App Service Plan"
  type        = string
}

variable "app_service_plan_location" {
  description = "Location of the existing App Service Plan"
  type        = string
}

variable "smtp_host" {
  type = string
}
variable "vaultwarden_smtp_from" {
  type = string
}

variable "vaultwarden_smtp_username" {
  type      = string
  sensitive = true
}
variable "vaultwarden_smtp_password" {
  type      = string
  sensitive = true
}
