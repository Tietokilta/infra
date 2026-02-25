{
  config,
  pkgs,
  lib,
  ...
}:
let
  enable = config.services.discourse.enable && config.services.tik-backup.enable;
  backupMount = config.services.tik-backup.storageboxMountPath;

  backupScript = pkgs.writeShellApplication {
    name = "discourse-backup";
    runtimeInputs = with pkgs; [
      rsync
      util-linux
      findutils
    ];
    text = ''
      set -euo pipefail
      if ! mountpoint -q "${backupMount}"; then
        echo "Nothing mounted on ${backupMount}, refusing to rsync" >&2
        exit 1
      fi
      backupDir="${backupMount}/backup/pannu/discourse/"
      mkdir -p "$backupDir"

      dataDir=/var/lib/discourse/backups/
      cd "$dataDir"
      # Only move files that have not been written to recently, to prevent
      # backing up partially written tarballs
      find . -mmin +10 -print0 | \
        rsync \
          --archive \
          --hard-links \
          --acls \
          --xattrs \
          --partial \
          --ignore-existing \
          --from0 \
          --files-from=- \
          . \
          "$backupDir"
    '';
  };
in
{
  systemd.services.discourse-backup = lib.mkIf enable {
    description = "Service to run Discourse backup";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    restartIfChanged = false;
    startAt = [ "03:45" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe backupScript;
    };
  };
}
