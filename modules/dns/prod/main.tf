# MX records for tietokilta.fi
resource "azurerm_dns_mx_record" "root_mx" {
  name                = "@"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
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

# Google site verification key for tietokilta.fi
resource "azurerm_dns_txt_record" "root_google_verification" {
  name                = "@"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300

  record {
    value = "google-site-verification=OVm2WzCdpqDTSv0LiDyGGutXT0I8YIlBwuyRHyMJFfw"
  }
}

# SPF record for tietokilta.fi
resource "azurerm_dns_txt_record" "root_spf" {
  name                = "@"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300

  record {
    value = "v=spf1 include:_spf.google.com include:mailgun.org a:tietokilta.fi ~all"
  }
}

# DKIM key for G Suite
resource "azurerm_dns_txt_record" "root_dkim_google" {
  name                = "google._domainkey"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300

  record {
    value = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmKCng0S4J1z5VFiL3lu1LIX9K/9CboGePYheGW3WXH71sBlGDILXyapA+caMb5QmyOG5UzXxr9VyBiwP7TEhVveflf94TN7U1pn7DayMrDgVNy2/DUgljyKIfP6m6IyF+9qg/L19S2K7MWt/GO4odLHsvvsDmyEUMbhd+2D612yzVIKtaHocSLiInfF1+YcRcF7h/4fKRTscyjlhAIEVRV8wrKyEcogOnYbuwoDCmzwQs7P57vS4/BBabyifvgs+c8+NGcqytsCaJ6DvWBStwTMAF+FahdoO8U7jUKCULE81SR1onSt2glMXQyqkXoYpq0xhlzUz3DOKp5DUV9WDJQIDAQAB"
  }
}

# DKIM key, no idea what this is used for
resource "azurerm_dns_txt_record" "root_dkim_default" {
  name                = "default._domainkey"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300

  record {
    value = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3WW6vxgnjzq3sbjziGnfWT2/6V/9ln0lXE+gUc6ntqdylb1v5knW7KqmWkEglGEn+Fd7urds7yJtNMEj7d1gHB1tB+mhtzc9BpOZPWbYihBeTws4mWSY+xx6mjz/VvhPhHlS/mTalJCoQOgFYu6D27e3+Y4e6xjbwfBIKujaQNoukdu8dsVMmFs5AbIjtdAMBrVfl5n9K730foa1qTNypmXz5JgSbJOpVnyCFbD+q39KCcR8Cz/M6BhKPq+XMJO82LAoSsdWIDAIm+Mt9QWd7anqLU0fCYmDwMg4pdWuUUoDRStL7zlFiCiOpWPAxnZ+wzSX5YPoHmh1q+tS0aC+jwIDAQAB"
  }
}

# Reporting-only DMARC policy
resource "azurerm_dns_txt_record" "root_dmarc" {
  name                = "_dmarc"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300

  record {
    value = "v=DMARC1;p=none;sp=none;rua=mailto:dmarc@tietokilta.fi!10m;ruf=mailto:dmarc@tietokilta.fi!10m"
  }
}

# Accept DMARC reports at root domain for list.tietokila.fi
resource "azurerm_dns_txt_record" "root_dmarc_reports_list_tietokila" {
  name                = "list.tietokila.fi._report._dmarc"
  resource_group_name = azurerm_resource_group.dns_rg.name
  zone_name           = azurerm_dns_zone.root_zone.name
  ttl                 = 300

  record {
    value = "v=DMARC1;"
  }
}

# Game servers (?)

resource "azurerm_dns_a_record" "mc_a" {
  name                = "mc"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = ["82.130.42.53"]
}

resource "azurerm_dns_a_record" "mcmap_a" {
  name                = "mcmap"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = ["82.130.42.53"]
}

resource "azurerm_dns_a_record" "ttt_a" {
  name                = "ttt"
  resource_group_name = var.dns_resource_group_name
  zone_name           = var.root_zone_name
  ttl                 = 300
  records             = ["82.130.42.53"]
}
