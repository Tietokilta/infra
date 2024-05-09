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
  project_id = mongodbatlas_project.project.id
  name       = var.serverless_instance_name

  provider_settings_backing_provider_name = "AZURE"
  provider_settings_provider_name         = "SERVERLESS"
  provider_settings_region_name           = var.atlas_region

  auto_indexing = true
}

resource "mongodbatlas_project_ip_access_list" "test" {
  project_id = mongodbatlas_project.project.id
  cidr_block = "0.0.0.0/0"
  comment    = "Public access (yolo)"
}
