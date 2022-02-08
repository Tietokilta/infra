variable "strapi_admin_jwt_secret" {
  type      = string
  sensitive = true
}

variable "ilmo_edit_token_secret" {
  type      = string
  sensitive = true
}

variable "ilmo_auth_jwt_secret" {
  type      = string
  sensitive = true
}

variable "tikjob_ghost_mail_username" {
  type = string
}

variable "tikjob_ghost_mail_password" {
  type      = string
  sensitive = true
}

variable "tikjob_cert_password" {
  type      = string
  sensitive = true
}
