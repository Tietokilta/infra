terraform {
  required_version = ">= 1.5.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.58"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "azurerm" {
    container_name       = "tfstate"
    key                  = "hetzner.tfstate"
    resource_group_name  = "terraform-state"
    storage_account_name = "tikprodterraform"
  }
}

provider "hcloud" {
  # Token via HCLOUD_TOKEN env var
}

resource "hcloud_firewall" "tikpannu" {
  name = "tikpannu"

  # SSH
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTP
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "tikpannu" {
  name        = "tikpannu"
  server_type = "cx23"
  location    = "hel1"
  image       = "ubuntu-24.04"

  firewall_ids = [hcloud_firewall.tikpannu.id]

  delete_protection  = true
  rebuild_protection = true

  labels = {
    environment = "production"
    managed_by  = "terraform"
  }

  user_data = <<-EOF
    #cloud-config
    runcmd:
      - curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-unstable NIXOS_IMPORT=./configuration.nix bash 2>&1 | tee /tmp/infect.log
    disk_setup:
      /dev/sda:
        table_type: gpt
        layout:
          - [1, 82]
          - [99]
        overwrite: false
    fs_setup:
      - label: boot
        filesystem: ext4
        device: /dev/sda1
      - label: nixos
        filesystem: ext4
        device: /dev/sda2
  EOF

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [image, ssh_keys, user_data]
  }
}

resource "random_password" "storagebox" {
  length           = 32
  special          = true
  override_special = "!$%/()=?+#-.,;:~*@{}_&"
}

resource "hcloud_storage_box" "backup" {
  name             = "tikbox-1"
  location         = "hel1"
  storage_box_type = "bx11"
  password         = random_password.storagebox.result

  access_settings = {
    samba_enabled = true
  }

  delete_protection = true

  lifecycle {
    #prevent_destroy = true
    prevent_destroy = false
    ignore_changes  = [ssh_keys, password]
  }
}
