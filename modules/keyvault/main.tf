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

locals {
  keyvault_secrets = [
    "digitransit-subscription-key",
    "ilmo-auth-jwt-secret",
    "ilmo-edit-token-secret",
    "ilmo-mailgun-api-key",
    "ilmo-mailgun-domain",
    "invoice-mailgun-api-key",
    "tikjob-ghost-mail-username",
    "tikjob-ghost-mail-password",
    "tenttiarkisto-django-secret-key",
    "github-app-key",
    "google-oauth-client-id",
    "google-oauth-client-secret",
    "muistinnollaus-smtp-email",
    "muistinnollaus-smtp-password",
    "muistinnollaus-strapi-token",
    "muistinnollaus-paytrail-merchant-id",
    "muistinnollaus-paytrail-secret-key",
    "mongodb-atlas-public-key",
    "mongodb-atlas-private-key",
    "github-challenge-value",
    "mailgun-server",
    "mailgun-receiver",
    "mailgun-api-key",
    "mailgun-domain",
    "mailgun-url"
  ]
}


data "azurerm_key_vault_secret" "secret" {
  for_each     = toset(local.keyvault_secrets)
  name         = each.value
  key_vault_id = azurerm_key_vault.keyvault.id
}
