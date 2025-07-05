terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
    }
  }
}
provider "mongodbatlas" {
  public_key  = var.mongodb_atlas_public_key
  private_key = var.mongodb_atlas_private_key
}

data "mongodbatlas_roles_org_id" "org_id" {
}

resource "mongodbatlas_project" "project" {
  name   = var.project_name
  org_id = data.mongodbatlas_roles_org_id.org_id.org_id

  is_collect_database_specifics_statistics_enabled = true
  is_data_explorer_enabled                         = true
  is_extended_storage_sizes_enabled                = false
  is_performance_advisor_enabled                   = true
  is_realtime_performance_panel_enabled            = false
  is_schema_advisor_enabled                        = true
}

resource "mongodbatlas_serverless_instance" "serverless_instance" {
  project_id                              = mongodbatlas_project.project.id
  name                                    = var.serverless_instance_name
  termination_protection_enabled          = true
  provider_settings_backing_provider_name = "AZURE"
  provider_settings_provider_name         = "SERVERLESS"
  provider_settings_region_name           = var.atlas_region
  continuous_backup_enabled               = true
  auto_indexing                           = true
}

resource "mongodbatlas_project_ip_access_list" "test" {
  project_id = mongodbatlas_project.project.id
  cidr_block = "0.0.0.0/0"
  comment    = "Public access (yolo)"
}

resource "random_password" "mongodb_password" {
  length  = 32
  special = false
}

resource "mongodbatlas_database_user" "database_user" {
  username           = "cms"
  password           = random_password.mongodb_password.result
  project_id         = mongodbatlas_project.project.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "cms"
  }

  roles {
    role_name     = "readWrite"
    database_name = "payload"
  }
}
