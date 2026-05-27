{
  config,
  pkgs,
  lib,
  ...
}:
let
  enable = config.services.discourse.enable && config.services.tik-backup.enable;
  stagingDir = config.services.tik-backup.stagingDir;
  tmpDir = "/tmp/discourse-backup-snapshot";
  subdir = "discourse";

  stageToTmp = pkgs.writeShellApplication {
    name = "stage-discourse-backup-1";
    runtimeInputs = [ pkgs.acl ];
    text = ''
      set -euo pipefail
      discourseData=/var/lib/discourse/backups/default
      if [[ ! -d "$discourseData" || ! -O "$discourseData" ]]; then
        echo "$discourseData does not exist or is not owned by the current user" >&2
        exit 1
      fi

      # Discourse automatically creates tarballs of its state every day, we only
      # want to back up the latest one each time.
      #
      # Find the newest .tar.gz file that has been modified more than 5 minutes
      # ago (prevent backing up a tarball Discourse is still writing to), print
      # its last modified time + path;
      # Sort in reverse order based on time (newest first);
      # Take first;
      # Take fields from the second onwards (the path)
      newestBackup=$(
        find "$discourseData" \
          -maxdepth 1 \
          -mmin +5 \
          -type f \
          -name "*.tar.gz" \
          -printf '%T@ %p\n' \
        | sort -nr \
        | head -1 \
        | cut -d' ' -f2-
      )
      if [[ -z "$newestBackup" ]]; then
        echo "No backups found in $discourseData" >&2
        exit 1
      fi

      echo "Found $newestBackup to be the newest backup, staging..." >&2

      rm -rf "${tmpDir}"
      mkdir -m 700 "${tmpDir}"
      cp "$newestBackup" "${tmpDir}/"
      setfacl -Rm u:backup:rwX "${tmpDir}"
    '';
  };
  stagingScript = pkgs.writeShellApplication {
    name = "stage-discourse-backup-2";
    text = ''
      set -euo pipefail

      cp "${tmpDir}"/* "${stagingDir}/${subdir}/"
      rm -rf "${tmpDir}"/*
    '';
  };
in
{
  config = lib.mkIf enable {
    services.tik-backup = {
      stagingServices = [
        "discourse-stage-backup1.service"
        "discourse-stage-backup2.service"
      ];
      stagingSubdirs = [
        {
          inherit subdir;
          user = "backup";
        }
      ];
    };

    systemd.services = {
      discourse-stage-backup1 = {
        description = "Move discourse backup to /tmp for backup user";
        restartIfChanged = false;
        serviceConfig = {
          Type = "oneshot";
          User = "discourse";
          ExecStart = lib.getExe stageToTmp;
        };
      };
      discourse-stage-backup2 = {
        description = "Stage Discourse backup to ${stagingDir}";
        requires = [ "discourse-stage-backup1.service" ];
        after = [ "discourse-stage-backup1.service" ];
        restartIfChanged = false;
        serviceConfig = {
          Type = "oneshot";
          User = "backup";
          ExecStart = lib.getExe stagingScript;
        };
      };
    };
  };
}
