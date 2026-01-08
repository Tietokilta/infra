output "db_connection_string" {
  value     = replace(mongodbatlas_flex_cluster.flex_cluster.standard_srv, "mongodb+srv://", "mongodb+srv://cms:${random_password.mongodb_password.result}@")
  sensitive = true
}
