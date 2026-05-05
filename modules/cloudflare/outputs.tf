output "zone_id" {
  description = "The Cloudflare zone ID for tietokilta.fi"
  value       = data.cloudflare_zone.zone.id
}
