variable "env_name" {
  type = string
}

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

// MySQL

variable "mysql_fqdn" {
  type = string
}

variable "mysql_username" {
  type = string
}

variable "mysql_password" {
  type = string
}

variable "mysql_db_name" {
  type = string
}

// Storage

variable "storage_account_name" {
  type = string
}

variable "storage_account_key" {
  type = string
}

variable "storage_share_name" {
  type = string
}

// Ghost config

variable "ghost_mail_host" {
  type = string
}

variable "ghost_mail_port" {
  type = number
}

variable "ghost_mail_username" {
  type = string
}

variable "ghost_mail_password" {
  type = string
}

variable "ghost_front_url" {
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
