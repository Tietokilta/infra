terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.13.0"
    }
  }
}

# Configure aliased provider to connect as the Postgres administrator
provider "postgresql" {
  alias     = "admin"
  host      = var.postgres_server_fqdn
  port      = 5432
  username  = var.postgres_admin_username
  password  = var.postgres_admin_password
  sslmode   = "require"
  superuser = false
}
