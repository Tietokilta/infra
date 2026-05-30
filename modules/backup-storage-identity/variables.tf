variable "display_name" {
  description = "Display name for the Azure AD application registration."
  type        = string
  default     = "tik-backup-storage-reader"
}

variable "secret_display_name" {
  description = "Display name for the Azure AD application password."
  type        = string
  default     = "tik-backup-storage-reader-secret"
}

variable "snapshot_role_name" {
  description = "Name for the custom role allowing file share snapshot creation and deletion."
  type        = string
  default     = "tik-backup-file-share-snapshot"
}
