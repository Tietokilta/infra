{
  config,
  lib,
  ...
}:
let
  cfg = config.services.tik-backup;
in
{
  options.services.tik-backup.storageboxServer = lib.mkOption {
    type = lib.types.str;
    description = "Hetzner Storage Box server hostname (from terraform output storagebox_server)";
    example = "u123456.your-storagebox.de";
  };

  config = lib.mkIf cfg.enable {
    fileSystems.${cfg.mountPath} = {
      device = "//${cfg.storageboxServer}/backup";
      fsType = "cifs";
      options = [
        "credentials=${config.sops.secrets.storagebox-credentials.path}"
        "uid=root"
        "gid=root"
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
