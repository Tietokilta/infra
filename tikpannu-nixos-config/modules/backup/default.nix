{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tik-backup;
in
{
  imports = [
    ./storagebox.nix
    ./secrets.nix
  ];

  options.services.tik-backup = {
    enable = lib.mkEnableOption "Tietokilta backup system";

    backupPath = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/backup/restic-repo";
      description = "Path to the restic repository";
    };

    mountPath = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/backup";
      description = "Mount path for Hetzner Storage Box";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure cifs-utils is available
    environment.systemPackages = [ pkgs.cifs-utils ];

    # Base restic backup service (placeholder for Phase 2 data sources)
    services.restic.backups.tik-base = {
      initialize = true;
      repository = cfg.backupPath;
      passwordFile = config.sops.secrets.backup-restic-password.path;

      # Will be populated in Phase 2 with actual backup paths
      paths = [ "/var/backup" ];

      timerConfig = {
        OnCalendar = "04:00";
        RandomizedDelaySec = "30m";
      };

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
      ];
    };

    # Create backup staging directory
    systemd.tmpfiles.rules = [
      "d /var/backup 0750 root root -"
    ];
  };
}
