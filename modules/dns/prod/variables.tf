variable "dns_resource_group_name" {
  type = string
}

variable "root_zone_name" {
  type = string
}

variable "dmarc_report_domains" {
  type = set(string)
}
