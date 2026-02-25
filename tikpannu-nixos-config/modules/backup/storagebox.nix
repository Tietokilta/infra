{
  config,
  lib,
  ...
}:
let
  cfg = config.services.tik-backup;
in
{
  options.services.tik-backup = {
    enable = lib.mkEnableOption "backup service";

    storageboxMountPath = lib.mkOption {
      description = "The path to mount the backup on";
      type = lib.types.path;
      default = "/mnt/backup";
    };

    storageboxServer = lib.mkOption {
      description = "Hetzner storage box server hostname";
      type = lib.types.str;
      example = "u123456.your-storagebox.de";
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems.${cfg.storageboxMountPath} = {
      device = "//${cfg.storageboxServer}/backup";
      fsType = "cifs";
      options = [
        "credentials=${config.sops.secrets.storagebox-credentials.path}"
        "uid=root"
        "gid=root"
        "file_mode=0700"
        "dir_mode=0700"
        "_netdev"
        "nofail"
        "x-systemd.automount"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=10s"
        "x-systemd.mount-timeout=10s"
      ];
    };
  };
}
