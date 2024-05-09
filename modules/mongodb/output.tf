output "db_connection_string" {
  value     = "${replace(mongodbatlas_serverless_instance.serverless_instance.connection_strings_standard_srv, "mongodb+srv://", "mongodb+srv://cms:${random_password.mongodb_password.result}@")}/cms?retryWrites=true&w=majority"
  sensitive = true
}
