data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyvault" {
  name                        = "tikweb-keyvault-${var.env_name}"
  location                    = var.resource_group_location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

data "azurerm_key_vault_secret" "strapi_admin_jwt_secret" {
  name         = "strapi-admin-jwt-secret"
  key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "strapi_jwt_secret" {
  name         = "strapi-jwt-secret"
  key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "strapi_api_token_salt" {
  name         = "strapi-api-token-salt"
  key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "strapi_app_keys" {
  name         = "strapi-app-keys"
  key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "ilmo_auth_jwt_secret" {
  name         = "ilmo-auth-jwt-secret"
  key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "ilmo_edit_token_secret" {
  name         = "ilmo-edit-token-secret"
  key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "ilmo_mailgun_api_key" {
  name         = "ilmo-mailgun-api-key"
  key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "ilmo_mailgun_domain" {
  name         = "ilmo-mailgun-domain"
  key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "tikjob_ghost_mail_username" {
  name         = "tikjob-ghost-mail-username"
  key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "tikjob_ghost_mail_password" {
  name         = "tikjob-ghost-mail-password"
  key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "tenttiarkisto_django_secret_key" {
  name         = "tenttiarkisto-django-secret-key"
  key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "github_app_key" {
  name         = "github-app-key"
  key_vault_id = azurerm_key_vault.keyvault.id
}
