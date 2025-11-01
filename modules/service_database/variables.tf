variable "postgres_server_fqdn" {
  type = string
}

variable "postgres_admin_password" {
  type      = string
  sensitive = true
}

variable "postgres_admin_username" {
  type    = string
  default = "tietokilta"
}

variable "postgres_server_id" {
  type = string
}

variable "db_name" {
  type = string
}
