# Pull-based deployment, adapted from nix-community/infra
# (modules/nixos/common/update.{nix,bash}).
#
# CI (.github/workflows/deploy-pannu.yml) builds the system on every push to
# main, pushes it to Cachix and pins the store path as `<hostname>` in the
# Cachix cache. This timer fetches that pin, substitutes the closure from
# Cachix (signatures are checked by Nix) and switches to it. The flake is never
# evaluated on the host.
#
# If the new system has a different kernel, initrd or kernel modules, a reboot
# is scheduled for `rebootTime`.
#
# Every run is reported to https://status.tietokilta.fi (`tikpannu-update`).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tik-update-host;
  gatus = import ../lib/gatus.nix { inherit pkgs lib; };

  cacheName = "tietokilta";
  pinName = config.networking.hostName;

  update-host = pkgs.writeShellApplication {
    name = "update-host";
    runtimeInputs = [
      config.nix.package
      config.system.build.nixos-rebuild
      config.systemd.package
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      cache=${lib.escapeShellArg cacheName}
      pin=${lib.escapeShellArg pinName}
      reboot_time=${lib.escapeShellArg cfg.rebootTime}

      p=$(curl -fsS --retry 3 "https://app.cachix.org/api/v1/cache/$cache/pin" |
        jq -er --arg n "$pin" '.[] | select(.name == $n) | .lastRevision.storePath')

      if [[ ! "$p" =~ ^/nix/store/[0-9a-z]{32}-nixos-system-"$pin"-[^/]+$ ]]; then
        echo "Unexpected store path in pin '$pin': $p" >&2
        exit 1
      fi

      current=$(readlink /run/current-system)
      if [[ "$current" == "$p" ]]; then
        echo "Already running $p"
        exit 0
      fi

      echo "Updating $current -> $p"
      nix-store --option narinfo-cache-negative-ttl 0 --realise "$p"
      nixos-rebuild switch --store-path "$p"

      for f in kernel initrd kernel-modules; do
        if [[ "$(readlink -f "/run/booted-system/$f")" != "$(readlink -f "$p/$f")" ]]; then
          # Cancelling the reboot (stopping the timer) holds until the next update
          if systemctl is-active --quiet update-host-reboot.timer; then
            echo "New $f, reboot already scheduled"
          else
            echo "New $f, scheduling a reboot at $reboot_time"
            # After=: don't reboot in the middle of an update
            systemd-run \
              --unit=update-host-reboot \
              --description="Reboot into the system deployed by update-host" \
              --on-calendar="$reboot_time" \
              --property=After=update-host.service \
              ${config.systemd.package}/bin/systemctl reboot
          fi
          break
        fi
      done
    '';
  };

  mkHeartbeatService =
    success:
    gatus.mkHeartbeatService {
      endpoint = "_tikpannu-update";
      inherit success;
      error = lib.optionalString (!success) "update-host failed, see journalctl -u update-host";
      environmentFile = config.sops.templates.update-host-gatus-envfile.path;
    };
in
{
  options.services.tik-update-host = {
    enable = lib.mkEnableOption "pulling and switching to the latest system built by CI";

    rebootTime = lib.mkOption {
      type = lib.types.str;
      # Night, before the backups at 04:00 (./backup/configuration.nix)
      default = "03:00 Europe/Helsinki";
      description = ''
        When to reboot after an update that changes the kernel, initrd or
        kernel modules, in `systemd.time(7)` calendar event format.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nix.settings = {
      substituters = [ "https://${cacheName}.cachix.org" ];
      trusted-public-keys = [ "tietokilta.cachix.org-1:Vz36YHwKEz8q6aq+UI8AqE1ceh/ALsRT2ICR819YHUY=" ];
    };

    # In the default sops file, shared with the backup heartbeats (Gatus `$BACKUPS_TOKEN`)
    sops.secrets.gatus-token = { };
    sops.templates.update-host-gatus-envfile.content = ''
      GATUS_TOKEN="${config.sops.placeholder.gatus-token}"
    '';

    systemd.services = {
      update-host = {
        description = "Switch to the latest ${pinName} system built by CI";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        # Don't let switch-to-configuration stop or restart the unit running it
        restartIfChanged = false;
        unitConfig.X-StopOnRemoval = false;
        onSuccess = [ "update-host-success.service" ];
        onFailure = [ "update-host-failure.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe update-host;
        };
      };

      update-host-success = mkHeartbeatService true;
      update-host-failure = mkHeartbeatService false;
    };

    systemd.timers.update-host = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitInactiveSec = "5m";
      };
    };
  };
}
