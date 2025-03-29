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
