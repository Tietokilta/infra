terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

# Requires the zone to be added to the Cloudflare account manually first,
# then NS records updated at the registrar to point to Cloudflare.
data "cloudflare_zone" "zone" {
  filter = {
    name = var.zone_name
  }
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = data.cloudflare_zone.zone.id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = data.cloudflare_zone.zone.id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = data.cloudflare_zone.zone.id
  setting_id = "min_tls_version"
  value      = "1.2"
}

resource "cloudflare_zone_setting" "automatic_https_rewrites" {
  zone_id    = data.cloudflare_zone.zone.id
  setting_id = "automatic_https_rewrites"
  value      = "on"
}

resource "cloudflare_zone_setting" "opportunistic_encryption" {
  zone_id    = data.cloudflare_zone.zone.id
  setting_id = "opportunistic_encryption"
  value      = "on"
}

resource "cloudflare_zone_setting" "http3" {
  zone_id    = data.cloudflare_zone.zone.id
  setting_id = "http3"
  value      = "on"
}

# Cache Next.js static assets for one year (filenames include content hashes)
resource "cloudflare_ruleset" "cache_rules" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "tikweb cache rules"
  kind    = "zone"
  phase   = "http_request_cache_settings"

  rules = [{
    action      = "set_cache_settings"
    description = "Cache Next.js static assets for 1 year"
    enabled     = true
    expression  = "(http.request.uri.path matches \"^/_next/static/\")"
    action_parameters = {
      cache = true
      edge_ttl = {
        mode    = "override_origin"
        default = 31536000 # 1 year
        status_code_ttl = [{
          status_code = 200
          value       = 31536000
        }]
      }
      browser_ttl = {
        mode    = "override_origin"
        default = 31536000
      }
    }
  }]
}

# Root domain MX records (Google Workspace)
resource "cloudflare_dns_record" "mx_aspmx" {
  zone_id  = data.cloudflare_zone.zone.id
  name     = "@"
  type     = "MX"
  content  = "aspmx.l.google.com"
  priority = 0
  ttl      = 300
}

resource "cloudflare_dns_record" "mx_alt1_aspmx" {
  zone_id  = data.cloudflare_zone.zone.id
  name     = "@"
  type     = "MX"
  content  = "alt1.aspmx.l.google.com"
  priority = 5
  ttl      = 300
}

resource "cloudflare_dns_record" "mx_alt3_aspmx" {
  zone_id  = data.cloudflare_zone.zone.id
  name     = "@"
  type     = "MX"
  content  = "alt3.aspmx.l.google.com"
  priority = 10
  ttl      = 300
}

resource "cloudflare_dns_record" "mx_tietokilta" {
  zone_id  = data.cloudflare_zone.zone.id
  name     = "@"
  type     = "MX"
  content  = "tietokilta.fi"
  priority = 20
  ttl      = 300
}

resource "cloudflare_dns_record" "mx_mail_cs_hut" {
  zone_id  = data.cloudflare_zone.zone.id
  name     = "@"
  type     = "MX"
  content  = "mail.cs.hut.fi"
  priority = 21
  ttl      = 300
}

# Root TXT records
resource "cloudflare_dns_record" "txt_google_verification" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "@"
  type    = "TXT"
  content = "google-site-verification=OVm2WzCdpqDTSv0LiDyGGutXT0I8YIlBwuyRHyMJFfw"
  ttl     = 300
}

resource "cloudflare_dns_record" "txt_spf" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "@"
  type    = "TXT"
  content = "v=spf1 include:_spf.google.com include:mailgun.org a:tietokilta.fi ~all"
  ttl     = 300
}

# DKIM records (Google Workspace)
resource "cloudflare_dns_record" "txt_dkim_google" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "google._domainkey"
  type    = "TXT"
  content = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmKCng0S4J1z5VFiL3lu1LIX9K/9CboGePYheGW3WXH71sBlGDILXyapA+caMb5QmyOG5UzXxr9VyBiwP7TEhVveflf94TN7U1pn7DayMrDgVNy2/DUgljyKIfP6m6IyF+9qg/L19S2K7MWt/GO4odLHsvvsDmyEUMbhd+2D612yzVIKtaHocSLiInfF1+YcRcF7h/4fKRTscyjlhAIEVRV8wrKyEcogOnYbuwoDCmzwQs7P57vS4/BBabyifvgs+c8+NGcqytsCaJ6DvWBStwTMAF+FahdoO8U7jUKCULE81SR1onSt2glMXQyqkXoYpq0xhlzUz3DOKp5DUV9WDJQIDAQAB"
  ttl     = 300
}

resource "cloudflare_dns_record" "txt_dkim_default" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "default._domainkey"
  type    = "TXT"
  content = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3WW6vxgnjzq3sbjziGnfWT2/6V/9ln0lXE+gUc6ntqdylb1v5knW7KqmWkEglGEn+Fd7urds7yJtNMEj7d1gHB1tB+mhtzc9BpOZPWbYihBeTws4mWSY+xx6mjz/VvhPhHlS/mTalJCoQOgFYu6D27e3+Y4e6xjbwfBIKujaQNoukdu8dsVMmFs5AbIjtdAMBrVfl5n9K730foa1qTNypmXz5JgSbJOpVnyCFbD+q39KCcR8Cz/M6BhKPq+XMJO82LAoSsdWIDAIm+Mt9QWd7anqLU0fCYmDwMg4pdWuUUoDRStL7zlFiCiOpWPAxnZ+wzSX5YPoHmh1q+tS0aC+jwIDAQAB"
  ttl     = 300
}

# DMARC
resource "cloudflare_dns_record" "txt_dmarc" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  ttl     = 300
}

# DMARC report authorization for subdomains that send reports to root
resource "cloudflare_dns_record" "txt_dmarc_reports" {
  for_each = var.dmarc_report_domains
  zone_id  = data.cloudflare_zone.zone.id
  name     = "${each.key}._report._dmarc"
  type     = "TXT"
  content  = "v=DMARC1;"
  ttl      = 300
}

# Minecraft game server
resource "cloudflare_dns_record" "mc_a" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "mc"
  type    = "A"
  content = "65.109.127.222"
  proxied = false
  ttl     = 300
}

resource "cloudflare_dns_record" "mc_srv" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "_minecraft._tcp"
  type    = "SRV"
  data = {
    priority = 0
    weight   = 5
    port     = 10015
    target   = "mc.tietokilta.fi"
  }
  ttl = 300
}

# GitHub org challenge
resource "cloudflare_dns_record" "txt_github_challenge" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "_github-challenge-Tietokilta-org"
  type    = "TXT"
  content = var.github_challenge_value
  ttl     = 60
}
