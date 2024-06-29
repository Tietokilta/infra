variable "resource_group_name" {
  type = string
}

variable "zone_name" {
  type = string
}
variable "challenge_name" {
  type = string
}
variable "challenge_value" {
  type = string
}
resource "azurerm_dns_txt_record" "github_challenge" {
  name                = var.challenge_name
  resource_group_name = var.resource_group_name
  zone_name           = var.zone_name
  ttl                 = 60
  record {
    value = var.challenge_value
  }
}
