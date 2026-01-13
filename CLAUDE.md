# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the infrastructure repository for Tietokilta (Computer Science Guild), managing Azure cloud resources via Terraform and a NixOS server configuration for pannu.tietokilta.fi.

## Common Commands

### Terraform (Azure Infrastructure)

```bash
# Initialize (requires Azure login first)
az login
terraform init
terraform workspace select prod

# Preview changes
terraform plan

# Apply changes (prefer letting CI do this on main branch)
terraform apply

# Format code before committing
terraform fmt -recursive
```

### Nix (tikpannu server)

```bash
# Enter development shell (provides azure-cli, sops, terraform)
nix develop

# Format all code (Nix, Terraform, YAML)
nix fmt

# Run flake checks including NixOS tests
nix flake check -L

# Build NixOS configuration locally
nix build .#nixosConfigurations.tikpannu.config.system.build.toplevel -L

# Build and run VM for local testing
nix run .#nixosConfigurations.tikpannu.config.system.build.vm

# Manual deployment (prefer CI)
nixos-rebuild switch --target-host root@pannu.tietokilta.fi --flake .#tikpannu
```

### Pre-commit Hook

```bash
./setup-pre-commit.sh  # Installs formatter hook
```

## Architecture

### Two Main Components

1. **Terraform** (`main.tf`, `modules/`): Azure resources for various Tietokilta services
2. **NixOS** (`tikpannu-nixos-config/`, `flake.nix`): Server configuration for pannu.tietokilta.fi

### Terraform Structure

- `main.tf` - Root module, provider configuration, module instantiation
- `modules/` - Service-specific modules (ilmo, web, forum, registry, vaultwarden, etc.)
- `modules/common/` - Shared resources (resource group, networking)
- `modules/dns/` - DNS zone management
- `modules/keyvault/` - Secret management

Backend state stored in Azure (`tikprodterraform` storage account).

### NixOS Structure (tikpannu-nixos-config/)

Hosts: Discourse (vaalit.tietokilta.fi), Telegram bots (TiKbot, WappuPokemonBot, SummerBodyBot)

- `configuration.nix` - Main system config
- `modules/discourse/` - Discourse forum config with sops-nix secrets
- `modules/tikbots/` - Telegram bot services
- `modules/secrets/sops.nix` - Secret declarations
- `tests/` - NixOS VM tests

Secrets managed via sops-nix. Use `sops updatekeys <file>` to add new key access.

## CI/CD Workflows

- **terraform.yml**: Runs `plan` on PRs, `apply` on main (for non-Nix changes)
- **deploy-pannu.yml**: Builds and deploys NixOS config on main (for `*.nix` changes)
- **format-check.yml**: Validates formatting via `nix build .#checks.<system>.formatting`

## Key Patterns

### Importing Existing Azure Resources

When Terraform tries to create an existing resource:
```bash
terraform import module.<foo>.<bar> /subscriptions/<subscription-id>/<path>
```

### Adding Secrets to sops-nix

1. Edit `.sops.yaml` to add key to `keys` and `key_groups`
2. Run `sops updatekeys <secret file>` (requires existing access)
