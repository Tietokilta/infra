# NixOS configuration for pannu.tietokilta.fi

This directory defines the system that hosts at least vaalit.staging.tietokilta.fi
(soon to be vaalit.tietokilta.fi), and the Telegram bots TiKbot, WappuPokemonBot,
and SummerBodyBot. The configuration also defines the aforementioned services themselves.

## General configuration
`./hardware-configuration.nix` and `./networking.nix` should generally not be modified
unless you really know what you're doing. `./configuration.nix` has general configuration
of the system.

### Secrets
Secrets are managed using [sops-nix](https://github.com/Mic92/sops-nix), which itself
uses [sops](https://github.com/getsops/sops). The `sops` CLI tool is required to manage
the secrets, and it should be provided in this repo's devshell. An example on how
to use sops-nix can be found [here](https://github.com/Mic92/sops-nix?tab=readme-ov-file#usage-example).

`./.sops.yaml` defines which keys have access to which secrets. Adding access can only
be done by a user who already has access. To add a new key:
```bash
# Use your favorite editor to add the new key to `keys`,
# and that key to the proper `key_groups`
$EDITOR .sops.yaml

# This command must be run by a user who already has access
# The `.sops.yaml` file must be in the same directory this command is run in
sops updatekeys <secret file>
```

For an example on how the secrets can be used in the NixOS configuration, see
`./modules/discourse/`.


## vaalit.staging.tietokilta.fi (Discourse)
*See [./modules/discourse/](./modules/discourse/)*  
Discourse is configured using [the Discourse module](https://search.nixos.org/options?channel=unstable&query=services.discourse)
provided by Nixpkgs.

## Telegram bots
*See [./modules/tikbots/](./modules/tikbots/)*  
The Telegram bots are configured through NixOS modules provided by 
[`Tietokilta/tikbots`](https://github.com/Tietokilta/tikbots/tree/main/nixos), where you
can find the definitions for each module.

> [!Warning]  
> Do not set secret environment variables, such as a Telegram bot token,
> with the `env` option, as they will be public. Use the `envFile` option
> together with sops-nix for all secret environment variables

You can use the `env` option of the bot modules to set environment variables that
are used in the systemd services that run the bots.

The `envFile` option similarly sources environment variables from the specified
file into the service. This option should be used with sops-nix for secrets.

## Deployment
We have a [GitHub Actions workflow](../.github/workflows/deploy-pannu.yml) that
automatically deploys any configuration changes pushed to the `main` branch. This
should be the preferred method of deployment.

If required, `nixos-rebuild switch` can be used like so, provided you have SSH access:
```bash
# The `--flake` argument has two parts separated by a `#`
# First a path to the directory containing the flake.nix file to be used,
# and secondly the `nixosConfiguration` attribute to use from the flake
nixos-rebuild switch \
  --target-host root@pannu.tietokilta.fi \
  --flake ..#tikpannu
```

## Testing the config
[./modules/test-vm.nix](./modules/test-vm.nix) defines options that will only be
used when building a virtual machine with `nixos-rebuild build-vm` and equivalents,
and are thus not taken into account for the actual config deployed to the server.

The VM has a very minimalistic window manager that can be started by running
`startx` in the tty, as well as Firefox.

> [!Note]  
> There is nothing special about the file itself, just that options defined
> inside of `virtualisation.vmVariant` are only defined for the virtual machine
> variants of built configurations

It defines a user `test` with the password `test` that has sudo privileges.
Entries in `networking.extraHosts` are placed in `/etc/hosts`. For example:
```nix
networking.extraHosts = ''
  127.0.0.1 pannu.tietokilta.fi
'';
```
means that the address 'pannu.tietokilta.fi' resolves to 127.0.0.1 (localhost)
instead of the real address.

> [!Note]  
> If you want to test the Telegram bots, make sure you aren't on Aalto WiFi,
> as it has blocked the Telegram API  
>
> The Discourse service also takes a while to start, follow its logs with
> `journalctl -efu discourse.service`


The VM does not have access to the real secrets and thus they just have temp (:D)
values in their place. The Discourse instance should run OOTB, but the Telegram bots
need to be given a real [token](https://core.telegram.org/bots/tutorial#obtain-your-bot-token)
for testing. See the beginning of [./modules/test-vm.nix](./modules/test-vm.nix) to
define the secrets, and remember to not accidentally commit them.

The VM can be built and ran with:
```bash
nix run ..#nixosConfigurations.tikpannu.config.system.build.vm
```

