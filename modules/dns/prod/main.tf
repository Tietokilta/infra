# MX records for tietokilta.fi
resource "azurerm_dns_mx_record" "root_mx" {
  name                = "@"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    preference = 0
    exchange   = "aspmx.l.google.com"
  }
  record {
    preference = 5
    exchange   = "alt1.aspmx.l.google.com"
  }
  record {
    preference = 10
    exchange   = "alt3.aspmx.l.google.com"
  }
  record {
    preference = 20
    exchange   = "tietokilta.fi"
  }
  record {
    preference = 21
    exchange   = "mail.cs.hut.fi"
  }
}

resource "azurerm_dns_txt_record" "root_txt" {
  name                = "@"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  # Google site verification key
  record {
    value = "google-site-verification=OVm2WzCdpqDTSv0LiDyGGutXT0I8YIlBwuyRHyMJFfw"
  }
  # SPF record
  record {
    value = "v=spf1 include:_spf.google.com include:mailgun.org a:tietokilta.fi ~all"
  }
}

# DKIM key for G Suite
resource "azurerm_dns_txt_record" "root_dkim_google" {
  name                = "google._domainkey"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmKCng0S4J1z5VFiL3lu1LIX9K/9CboGePYheGW3WXH71sBlGDILXyapA+caMb5QmyOG5UzXxr9VyBiwP7TEhVveflf94TN7U1pn7DayMrDgVNy2/DUgljyKIfP6m6IyF+9qg/L19S2K7MWt/GO4odLHsvvsDmyEUMbhd+2D612yzVIKtaHocSLiInfF1+YcRcF7h/4fKRTscyjlhAIEVRV8wrKyEcogOnYbuwoDCmzwQs7P57vS4/BBabyifvgs+c8+NGcqytsCaJ6DvWBStwTMAF+FahdoO8U7jUKCULE81SR1onSt2glMXQyqkXoYpq0xhlzUz3DOKp5DUV9WDJQIDAQAB"
  }
}

# DKIM key, no idea what this is used for
resource "azurerm_dns_txt_record" "root_dkim_default" {
  name                = "default._domainkey"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3WW6vxgnjzq3sbjziGnfWT2/6V/9ln0lXE+gUc6ntqdylb1v5knW7KqmWkEglGEn+Fd7urds7yJtNMEj7d1gHB1tB+mhtzc9BpOZPWbYihBeTws4mWSY+xx6mjz/VvhPhHlS/mTalJCoQOgFYu6D27e3+Y4e6xjbwfBIKujaQNoukdu8dsVMmFs5AbIjtdAMBrVfl5n9K730foa1qTNypmXz5JgSbJOpVnyCFbD+q39KCcR8Cz/M6BhKPq+XMJO82LAoSsdWIDAIm+Mt9QWd7anqLU0fCYmDwMg4pdWuUUoDRStL7zlFiCiOpWPAxnZ+wzSX5YPoHmh1q+tS0aC+jwIDAQAB"
  }
}

# Reporting-only DMARC policy
resource "azurerm_dns_txt_record" "root_dmarc" {
  name                = "_dmarc"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  }
}

# Accept DMARC reports at root domain
resource "azurerm_dns_txt_record" "root_dmarc_reports" {
  for_each = var.dmarc_report_domains

  name                = "${each.key}._report._dmarc"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    value = "v=DMARC1;"
  }
}

# Game servers (?)

resource "azurerm_dns_a_record" "mc_a_record" {
  name                = "mc"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = ["65.109.127.222"]
}

resource "azurerm_dns_srv_record" "mc_srv_record" {
  name                = "_minecraft._tcp"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300

  record {
    priority = 0
    weight   = 5
    port     = 10015
    target   = "mc.tietokilta.fi"
  }
}
