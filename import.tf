import {
  to = module.mongodb.mongodbatlas_flex_cluster.flex_cluster
  id = "663cfa071de1365615424b89-tikweb-serverless-instance"
}

removed {
  from = module.mongodb.mongodbatlas_serverless_instance.serverless_instance

  lifecycle {
    destroy = false
  }
}
