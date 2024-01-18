variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

// Certs

variable "acme_account_key" {
  type      = string
  sensitive = true
}

variable "dns_resource_group_name" {
  type = string
}
variable "subdomain" {
  type = string
}

variable "root_zone_name" {
  type = string
}


variable "app_service_plan_id" {
  type = string
}
variable "mongo_connection_string" {
  type      = string
  sensitive = true
}
variable "mongo_db_name" {
  type      = string
  sensitive = true
}
variable "google_oauth_client_id" {
  type      = string
  sensitive = true
}
variable "google_oauth_client_secret" {
  type      = string
  sensitive = true
}
variable "storage_connection_string" {
  type      = string
  sensitive = true
}

variable "storage_container_name" {
  type = string
}

variable "storage_account_base_url" {
  type = string
}
