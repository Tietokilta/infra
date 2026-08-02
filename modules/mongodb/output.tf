output "db_connection_string" {
  value     = replace(mongodbatlas_flex_cluster.flex_cluster.connection_strings.standard_srv, "mongodb+srv://", "mongodb+srv://cms:${random_password.mongodb_password.result}@")
  sensitive = true
}

# authSource is explicit so mongodump does not depend on the SRV TXT record
output "backup_connection_string" {
  value     = "${replace(mongodbatlas_flex_cluster.flex_cluster.connection_strings.standard_srv, "mongodb+srv://", "mongodb+srv://backup:${random_password.backup_password.result}@")}/?authSource=admin"
  sensitive = true
}
