variable "env_name" {
  type = string
}

variable "tikweb_rg_name" {
  type = string
}

variable "tikweb_rg_location" {
  type = string
}

variable "tikweb_app_plan_id" {
  type = string
}

variable "bot_token" {
  type      = string
  sensitive = true
}

variable "ghost_hook_secret" {
  type      = string
  sensitive = true
}

variable "channel_id" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "storage_account_access_key" {
  type      = string
  sensitive = true
}
