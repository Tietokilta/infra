output "ilmo_auth_jwt_secret" {
  value     = data.azurerm_key_vault_secret.ilmo_auth_jwt_secret.value
  sensitive = true
}

output "ilmo_edit_token_secret" {
  value     = data.azurerm_key_vault_secret.ilmo_edit_token_secret.value
  sensitive = true
}

output "ilmo_mailgun_api_key" {
  value     = data.azurerm_key_vault_secret.ilmo_mailgun_api_key.value
  sensitive = true
}

output "ilmo_mailgun_domain" {
  value     = data.azurerm_key_vault_secret.ilmo_mailgun_domain.value
  sensitive = true
}

output "tikjob_ghost_mail_username" {
  value     = data.azurerm_key_vault_secret.tikjob_ghost_mail_username.value
  sensitive = true
}

output "tikjob_ghost_mail_password" {
  value     = data.azurerm_key_vault_secret.tikjob_ghost_mail_password.value
  sensitive = true
}

output "tenttiarkisto_django_secret_key" {
  value     = data.azurerm_key_vault_secret.tenttiarkisto_django_secret_key.value
  sensitive = true
}

output "github_app_key" {
  value     = data.azurerm_key_vault_secret.github_app_key.value
  sensitive = true
}

output "google_oauth_client_id" {
  value     = data.azurerm_key_vault_secret.google_oauth_client_id.value
  sensitive = true
}

output "google_oauth_client_secret" {
  value     = data.azurerm_key_vault_secret.google_oauth_client_secret.value
  sensitive = true
}

output "mongo_db_connection_string" {
  value     = data.azurerm_key_vault_secret.mongo_db_connection_string.value
  sensitive = true
}
output "m0_smtp_email" {
  value     = data.azurerm_key_vault_secret.m0_smtp_email.value
  sensitive = true
}
output "m0_smtp_password" {
  value     = data.azurerm_key_vault_secret.m0_smtp_password.value
  sensitive = true
}
