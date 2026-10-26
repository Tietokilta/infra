output "fqdn" {
  value = module.app_service_hostname.fqdn
}

output "registry_app_id" {
  value = azurerm_linux_web_app.registry.id
}

output "oidc_signing_key_pem" {
  value     = tls_private_key.oidc_signing.private_key_pem
  sensitive = true
}

output "oidc_cookie_key" {
  value     = random_password.oidc_cookie_key.result
  sensitive = true
}
