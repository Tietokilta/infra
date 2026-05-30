data "azurerm_client_config" "current" {}

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
  subscription_scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
}

resource "azurerm_role_assignment" "backup_storage_reader" {
  scope                = local.subscription_scope
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.backup_storage.object_id
}

resource "azurerm_role_assignment" "backup_storage_blob_reader" {
  scope                = local.subscription_scope
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.backup_storage.object_id
}

resource "azurerm_role_assignment" "backup_storage_file_reader" {
  scope                = local.subscription_scope
  role_definition_name = "Storage File Data Privileged Reader"
  principal_id         = azuread_service_principal.backup_storage.object_id
}

resource "azurerm_role_definition" "file_share_snapshot" {
  name        = var.snapshot_role_name
  scope       = local.subscription_scope
  description = "Modify and delete file shares, needed to create and delete snapshots"

  permissions {
    actions = [
      "Microsoft.Storage/storageAccounts/fileServices/shares/write",
      "Microsoft.Storage/storageAccounts/fileServices/shares/delete",
    ]
  }

  assignable_scopes = [local.subscription_scope]
}

resource "azurerm_role_assignment" "backup_storage_file_snapshot" {
  scope              = local.subscription_scope
  role_definition_id = azurerm_role_definition.file_share_snapshot.role_definition_resource_id
  principal_id       = azuread_service_principal.backup_storage.object_id
}
