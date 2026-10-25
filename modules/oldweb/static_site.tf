# old.tietokilta.fi is a static archive built by Tietokilta/oldweb-static, served from this account's static website
# through Cloudflare. The app in main.tf stays reachable at its azurewebsites.net hostname until its data is archived
# and it is removed.
locals {
  fqdn                        = "${var.subdomain}.${var.root_zone_name}"
  static_site_storage_account = "oldwebstatic${var.environment}"
}

resource "azurerm_storage_account" "static_site" {
  name                            = local.static_site_storage_account
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  allow_nested_items_to_be_public = false # the static website endpoint is public regardless; blob URLs stay private
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  # The static website only answers requests for a registered domain; asverify proves ownership while old.tietokilta.fi
  # is proxied by Cloudflare and so resolves to Cloudflare, not to the account
  custom_domain {
    name          = local.fqdn
    use_subdomain = true
  }

  depends_on = [cloudflare_dns_record.static_site_asverify]

  lifecycle {
    # Azure doesn't return use_subdomain, so it would show as changed on every plan
    ignore_changes = [custom_domain[0].use_subdomain]
  }
}

resource "azurerm_storage_account_static_website" "static_site" {
  storage_account_id = azurerm_storage_account.static_site.id
  index_document     = "index.html"
  error_404_document = "404.html"
}

resource "cloudflare_dns_record" "static_site_asverify" {
  zone_id = var.cloudflare_zone_id
  name    = "asverify.${var.subdomain}"
  type    = "CNAME"
  content = "asverify.${local.static_site_storage_account}.blob.core.windows.net"
  proxied = false
  ttl     = 300
}

resource "cloudflare_dns_record" "static_site" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "CNAME"
  content = azurerm_storage_account.static_site.primary_web_host
  proxied = true
  ttl     = 1 # automatic, required for proxied records
}
