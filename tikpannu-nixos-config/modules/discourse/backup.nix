{
  config,
  pkgs,
  lib,
  ...
}:
let
  enable = config.services.discourse.enable && config.services.tik-backup.enable;
  stagingDir = config.services.tik-backup.stagingDir;
  subdir = "discourse";

  stagingScript = pkgs.writeShellApplication {
    name = "stage-discourse-backup";
    text = ''
      set -euo pipefail
      discourseData=/var/lib/discourse/backups/default
      targetDir="${stagingDir}/${subdir}/"
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
      umask 0002
      cp "$newestBackup" "$targetDir/"
    '';
  };
in
{
  config = lib.mkIf enable {
    services.tik-backup = {
      stagingServices = [ "discourse-stage-backup.service" ];
      stagingSubdirs = [
        {
          inherit subdir;
          user = "discourse";
        }
      ];
    };

    systemd.services.discourse-stage-backup = {
      description = "Stage Discourse backup to ${stagingDir}";
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe stagingScript;
        User = "discourse";
      };
    };
  };
}
