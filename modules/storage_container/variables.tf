variable "storage_account_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}
variable "resource_group_location" {
  type = string
}
variable "container_name" {
  type = string

}
variable "container_access_type" {
  type    = string
  default = "private"
}
