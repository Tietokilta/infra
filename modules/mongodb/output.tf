output "db_connection_string" {
  value = mongodbatlas_serverless_instance.serverless_instance.connection_strings_standard_srv
  sensitive = true
}
