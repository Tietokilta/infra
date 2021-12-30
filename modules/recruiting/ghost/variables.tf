variable "env_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

/* MySQL */
variable "mysql_fqdn" {
  type = string
}

variable "mysql_connection_user" {
  type = string
}

variable "mysql_password" {
  type = string
}

variable "mysql_db_name" {
  type = string
}

/* Storage */
variable "storage_account_name" {
  type = string
}

variable "storage_account_key" {
  type = string
}

variable "storage_share_name" {
  type = string
}

/* Ghost */
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
