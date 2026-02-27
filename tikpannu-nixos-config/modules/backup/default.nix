{ config, lib, ... }:
let
  cfg = config.services.tik-backup;
in
{
  imports = [
    ./configuration.nix
    ./storagebox.nix
    ./secrets.nix
    ./restic.nix
  ];

  options.services.tik-backup = {
    enable = lib.mkEnableOption "backup services";

    stagingDir = lib.mkOption {
      description = ''
        Staging directory to put backups in before moving to the restic repo.

        NOTE: this directory is cleaned up pre and post backing up to the restic
        repo via `rm -rf`. This option should not be set to a directory with
        data that cannot be deleted.
      '';
      type = lib.types.path;
      default = "/var/lib/backup";
    };

    stagingServices = lib.mkOption {
      description = ''
        Systemd services that stage backups into the staging directory for
        restic to backup to the SMB mount. These are ran before the restic
        backup happens.
      '';
      type = with lib.types; listOf str;
      default = [ ];
      example = [
        "discourse-stage-backup.service"
        "postgresql-stage-backup.service"
      ];
    };

    stagingSubdirs = lib.mkOption {
      description = ''
        Directories that should be created inside
        `config.services.tik-backup.stagingDir` for staging files to
      '';
      type = lib.types.listOf (
        lib.types.submodule {
          options.subdir = lib.mkOption {
            description = "Subdirectory name";
            type = lib.types.str;
            example = "discourse";
          };
          options.user = lib.mkOption {
            description = "User who owns the subdirectory";
            type = lib.types.str;
            example = "discourse";
          };
        }
      );
      default = [ ];
      example = [
        {
          subdir = "discourse";
          user = "discourse";
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = (
      [
        ''d "${cfg.stagingDir}" 0711 backup backup -''
      ]
      ++ map (def: ''d "${cfg.stagingDir}/${def.subdir}" 2770 ${def.user} backup -'') cfg.stagingSubdirs
    );
  };
}
