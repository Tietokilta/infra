terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}
