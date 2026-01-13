# Server
output "server_id" {
  description = "Hetzner server ID"
  value       = hcloud_server.tikpannu.id
}

output "server_ipv4" {
  description = "Public IPv4 address"
  value       = hcloud_server.tikpannu.ipv4_address
}

output "server_ipv6" {
  description = "Public IPv6 address"
  value       = hcloud_server.tikpannu.ipv6_address
}

# Storage Box
output "storagebox_id" {
  description = "Storage Box ID"
  value       = hcloud_storage_box.backup.id
}

output "storagebox_server" {
  description = "Storage Box server hostname for mounting"
  value       = hcloud_storage_box.backup.server
}

output "storagebox_username" {
  description = "Storage Box username"
  value       = hcloud_storage_box.backup.username
}

output "storagebox_password" {
  description = "Storage Box password (for NixOS sops secret)"
  value       = random_password.storagebox.result
  sensitive   = true
}
