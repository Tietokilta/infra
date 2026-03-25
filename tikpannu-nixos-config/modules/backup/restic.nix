{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.tik-backup;

  cleanupScript = pkgs.writeShellApplication {
    name = "stagingDir-cleanup";
    text = ''
      set -euo pipefail

      stagingDir=$(realpath "${cfg.stagingDir}")
      if [[ -z "$stagingDir" || "$stagingDir" == "/" || ''${#stagingDir} -lt 5 ]]; then
        echo "stagingDir is unset, /, or too short (is: '$stagingDir'), refusing to clean up" >&2
        exit 1
      fi

      if [[ ! -d "$stagingDir" || ! -O "$stagingDir" ]]; then
        echo "$stagingDir does not exist or not owned by 'backup', refusing to clean up" >&2
        exit 1
      fi

      shopt -s nullglob dotglob
      for fileOrDir in "$stagingDir"/*; do
        echo "Cleaning $fileOrDir" >&2
        if [[ -d "$fileOrDir" ]]; then
          rm -rf --one-file-system "''${fileOrDir:?}"/*
        else
          rm -f --one-file-system "$fileOrDir"
        fi
      done
    '';
  };
in
{
  options.services.tik-backup = {
    resticRepo = lib.mkOption {
      description = "Path to the restic repository";
      type = lib.types.path;
      default = "${cfg.storageboxMountPath}/restic-repo";
      defaultText = lib.literalExpression ''
        "''${cfg.storageboxMountPath}/restic-repo"
      '';
    };

    dates = lib.mkOption {
      description = ''
        The times that the backup will run. Format specified by `systemd.time(7)`
      '';
      type = with lib.types; listOf str;
      default = [ "04:00" ];
    };

    retentionFlags = lib.mkOption {
      description = ''
        Flags to define backup retentions via restic. These are passed to
        `restic forget --prune`, which is run after a backup.

        Without any options, nothing is deleted and everything is kept
        indefinitely.
      '';
      type = with lib.types; listOf str;
      default = [ ];
      example = [
        "--keep-daily 7"
        "--keep-weekly 4"
      ];
    };

    resticBackupName = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      visible = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.tik-backup.resticBackupName = "tik-backup";

    services.restic.backups.${cfg.resticBackupName} = {
      user = "backup";
      repository = cfg.resticRepo;
      initialize = true;
      passwordFile = config.sops.secrets.restic-password.path;

      paths = [
        cfg.stagingDir
      ];
      pruneOpts = cfg.retentionFlags;
      checkOpts = [
        "--with-cache"
      ];

      timerConfig = {
        OnCalendar = cfg.dates;
        Persistent = true;
        RandomizedDelaySec = "30min";
      };

      backupCleanupCommand = /* bash */ ''
        set -euo pipefail

        stagingDir=$(realpath "${cfg.stagingDir}")
        if [[ "$SERVICE_RESULT" != "success" ]]; then
          echo "Restic backup failed, keeping $stagingDir contents" >& 2
          exit
        fi

        ${lib.getExe cleanupScript}
      '';
    };

    systemd.services."restic-backups-${cfg.resticBackupName}" = {
      wants = cfg.stagingServices;
      after = cfg.stagingServices;
    };

    systemd.services."pre-${cfg.resticBackupName}-cleanup" = {
      requiredBy = cfg.stagingServices;
      before = cfg.stagingServices;
      serviceConfig = {
        Type = "oneshot";
        User = "backup";
        Group = "backup";
        ExecStart = lib.getExe cleanupScript;
      };
    };

    users = {
      users.backup = {
        group = "backup";
        isSystemUser = true;
      };
      groups.backup = { };
    };

    assertions = [
      {
        assertion = builtins.stringLength cfg.stagingDir >= 5;
        message = ''
          `services.tik-backup.stagingDir` is too short, dangerous for `rm -rf`
        '';
      }
      {
        assertion =
          !(lib.hasPrefix cfg.storageboxMountPath cfg.stagingDir)
          && !(lib.hasPrefix cfg.stagingDir cfg.storageboxMountPath);
        message = ''
          `services.tik-backup.stagingDir` exists inside
          `services.tik-backup.storageboxMountPath` or vice versa
        '';
      }
    ];
  };
}
