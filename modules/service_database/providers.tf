terraform {
  required_providers {
    postgresql = {
      source                = "cyrilgdn/postgresql"
      version               = ">= 1.13.0"
      configuration_aliases = [postgresql.admin]
    }
  }
}
