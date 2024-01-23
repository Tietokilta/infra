resource "random_string" "api_token_salt" {
  length  = 44 # 32 bytes base64 encoded will be 44 characters
  special = false
}

resource "random_string" "transfer_token_salt" {
  length  = 44
  special = false
}

resource "random_string" "admin_jwt_secret" {
  length  = 44
  special = false
}

resource "random_string" "jwt_secret" {
  length  = 44
  special = false
}

resource "random_string" "app_keys_1" {
  length  = 44
  special = false
}

resource "random_string" "app_keys_2" {
  length  = 44
  special = false
}

resource "random_string" "app_keys_3" {
  length  = 44
  special = false
}
