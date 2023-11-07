output "strapi_admin_jwt_secret" {
  value = data.azurerm_key_vault_secret.strapi_admin_jwt_secret.value
}

output "strapi_jwt_secret" {
  value = data.azurerm_key_vault_secret.strapi_jwt_secret.value
}

output "strapi_api_token_salt" {
  value = data.azurerm_key_vault_secret.strapi_api_token_salt.value
}

output "strapi_app_keys" {
  value = data.azurerm_key_vault_secret.strapi_app_keys.value
}

output "ilmo_auth_jwt_secret" {
  value = data.azurerm_key_vault_secret.ilmo_auth_jwt_secret.value
}

output "ilmo_edit_token_secret" {
  value = data.azurerm_key_vault_secret.ilmo_edit_token_secret.value
}

output "ilmo_mailgun_api_key" {
  value = data.azurerm_key_vault_secret.ilmo_mailgun_api_key.value
}

output "ilmo_mailgun_domain" {
  value = data.azurerm_key_vault_secret.ilmo_mailgun_domain.value
}

output "tikjob_ghost_mail_username" {
  value = data.azurerm_key_vault_secret.tikjob_ghost_mail_username.value
}

output "tikjob_ghost_mail_password" {
  value = data.azurerm_key_vault_secret.tikjob_ghost_mail_password.value
}
output "tenttiarkisto_django_secret_key" {
  value = data.azurerm_key_vault_secret.tenttiarkisto_django_secret_key.value
}

output "github_app_key" {
  value = data.azurerm_key_vault_secret.github_app_key.value
}
