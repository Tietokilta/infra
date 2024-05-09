output "fqdn" {
  value = local.fqdn
}
output "payload_password" {
  value     = random_password.payload_password.result
  sensitive = true
}