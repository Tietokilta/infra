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

variable "excluded_storage_accounts" {
  description = "Storage account names to exclude from role assignments."
  type        = list(string)
  default     = ["tikprodterraform"]
}
