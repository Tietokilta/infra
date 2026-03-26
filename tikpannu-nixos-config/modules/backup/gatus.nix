{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.tik-backup;
  gatusEndpoint = "https://status.tietokilta.fi/api/v1/endpoints/_backups/external";
  stagingServiceNames = map (name: lib.removeSuffix ".service" name) cfg.stagingServices;
  mkHeartbeatCommand =
    {
      success,
      error ? "unknown",
    }:
    /* bash */ ''
      ${lib.getExe pkgs.curl} \
        --fail-with-body \
        --silent \
        --show-error \
        -X POST \
        -H "Authorization: Bearer ''${GATUS_TOKEN}" \
        --url-query "success=${lib.boolToString success}" \
        --url-query "error=${error}" \
        ${gatusEndpoint}
    '';

  mkHeartbeatService = success: {
    serviceConfig = {
      Type = "oneshot";
      User = "backup";
      Group = "backup";
      EnvironmentFile = config.sops.templates.gatus-token-envfile.path;
      ExecStart = mkHeartbeatCommand {
        inherit success;
        error = "%I";
      };
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    sops.secrets.gatus-token = {
      sopsFile = ../secrets/backup.yaml;
    };
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
