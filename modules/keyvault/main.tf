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


}
data "azuread_service_principal" "CI_service_principal" {
  display_name = "github-action-terraform"
}


resource "azurerm_key_vault_access_policy" "CI" {
  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_service_principal.CI_service_principal.id

  key_permissions = [
    "Get",
    "Create",
    "Update"
  ]

  secret_permissions = [
    "Get",
    "Set"
  ]

}
resource "azuread_group" "admin" {
  display_name     = "tik_keyvault_rights"
  owners           = [data.azurerm_client_config.current.object_id]
  security_enabled = true
  lifecycle {
    ignore_changes = [members, owners]
  }
}
resource "azurerm_key_vault_access_policy" "admin" {
  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azuread_group.admin.id

  key_permissions = [
    "List",
    "Get",
    "Create",
    "Update"
  ]

  secret_permissions = [
    "List",
    "Get",
    "Set"
  ]

}

data "azurerm_key_vault_secret" "ilmo_auth_jwt_secret" {
  name         = "ilmo-auth-jwt-secret"
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on   = [azurerm_key_vault_access_policy.admin, azurerm_key_vault_access_policy.CI]
}

data "azurerm_key_vault_secret" "ilmo_edit_token_secret" {
  name         = "ilmo-edit-token-secret"
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on   = [azurerm_key_vault_access_policy.admin, azurerm_key_vault_access_policy.CI]
}

data "azurerm_key_vault_secret" "ilmo_mailgun_api_key" {
  name         = "ilmo-mailgun-api-key"
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on   = [azurerm_key_vault_access_policy.admin, azurerm_key_vault_access_policy.CI]
}

data "azurerm_key_vault_secret" "ilmo_mailgun_domain" {
  name         = "ilmo-mailgun-domain"
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on   = [azurerm_key_vault_access_policy.admin, azurerm_key_vault_access_policy.CI]
}

data "azurerm_key_vault_secret" "tikjob_ghost_mail_username" {
  name         = "tikjob-ghost-mail-username"
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on   = [azurerm_key_vault_access_policy.admin, azurerm_key_vault_access_policy.CI]
}

data "azurerm_key_vault_secret" "tikjob_ghost_mail_password" {
  name         = "tikjob-ghost-mail-password"
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on   = [azurerm_key_vault_access_policy.admin, azurerm_key_vault_access_policy.CI]
}

data "azurerm_key_vault_secret" "tenttiarkisto_django_secret_key" {
  name         = "tenttiarkisto-django-secret-key"
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on   = [azurerm_key_vault_access_policy.admin, azurerm_key_vault_access_policy.CI]
}

data "azurerm_key_vault_secret" "github_app_key" {
  name         = "github-app-key"
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on   = [azurerm_key_vault_access_policy.admin, azurerm_key_vault_access_policy.CI]
}
data "azurerm_key_vault_secret" "google_oauth_client_id" {
  name         = "google-oauth-client-id"
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on   = [azurerm_key_vault_access_policy.admin, azurerm_key_vault_access_policy.CI]
}
data "azurerm_key_vault_secret" "google_oauth_client_secret" {
  name         = "google-oauth-client-secret"
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on   = [azurerm_key_vault_access_policy.admin, azurerm_key_vault_access_policy.CI]
}
data "azurerm_key_vault_secret" "mongo_db_connection_string" {
  name         = "mongo-db-connection-string"
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on   = [azurerm_key_vault_access_policy.admin, azurerm_key_vault_access_policy.CI]
}
