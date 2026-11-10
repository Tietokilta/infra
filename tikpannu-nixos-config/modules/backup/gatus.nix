{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.tik-backup;
  gatus = import ../../lib/gatus.nix { inherit pkgs lib; };
  stagingServiceNames = map (name: lib.removeSuffix ".service" name) cfg.stagingServices;

  mkHeartbeatService =
    success:
    gatus.mkHeartbeatService {
      endpoint = "_backups";
      inherit success;
      error = "%I";
      environmentFile = config.sops.templates.gatus-token-envfile.path;
      serviceConfig = {
        User = "backup";
        Group = "backup";
      };
    };
in
{
  config = lib.mkIf cfg.enable {
    # In the default sops file, shared with update-host (../deployment.nix)
    sops.secrets.gatus-token = { };
    sops.templates.gatus-token-envfile = {
      owner = "backup";
      content = ''
        GATUS_TOKEN="${config.sops.placeholder.gatus-token}"
      '';
    };

    systemd.services = lib.mkMerge [
      {
        "backup-success@" = mkHeartbeatService true;
        "backup-failure@" = mkHeartbeatService false;
      }
      (lib.genAttrs
        (
          stagingServiceNames
          ++ [
            "restic-backups-${cfg.resticBackupName}"
            "pre-${cfg.resticBackupName}-cleanup"
          ]
        )
        (name: {
          onSuccess = [ "backup-success@%N.service" ];
          onFailure = [ "backup-failure@%N.service" ];
        })
      )
    ];
  };
}
