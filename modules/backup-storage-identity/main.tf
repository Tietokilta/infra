data "azurerm_client_config" "current" {}

data "azurerm_resources" "backup_storage_accounts" {
  type = "Microsoft.Storage/storageAccounts"
}

resource "azuread_application_registration" "backup_storage" {
  display_name = var.display_name
}

resource "azuread_service_principal" "backup_storage" {
  client_id = azuread_application_registration.backup_storage.client_id
}

resource "azuread_application_password" "backup_storage" {
  application_id = azuread_application_registration.backup_storage.id
  display_name   = var.secret_display_name
}

locals {
  backup_storage_account_scopes = {
    for resource in data.azurerm_resources.backup_storage_accounts.resources :
    resource.name => resource.id
    if !contains(var.excluded_storage_accounts, resource.name)
  }
}

resource "azurerm_role_assignment" "backup_storage_reader" {
  for_each = local.backup_storage_account_scopes

  scope                = each.value
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.backup_storage.object_id
}

resource "azurerm_role_assignment" "backup_storage_blob_reader" {
  for_each = local.backup_storage_account_scopes

  scope                = each.value
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.backup_storage.object_id
}

resource "azurerm_role_assignment" "backup_storage_file_reader" {
  for_each = local.backup_storage_account_scopes

  scope                = each.value
  role_definition_name = "Storage File Data Privileged Reader"
  principal_id         = azuread_service_principal.backup_storage.object_id
}
