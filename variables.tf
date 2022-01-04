variable "strapi_admin_jwt_secret" {
  type      = string
  sensitive = true
}

variable "ghost_mail_username" {
  type = string
}

variable "ghost_mail_password" {
  type      = string
  sensitive = true
}
