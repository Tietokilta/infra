{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.tik-backup;
  subdir = "mongodb";
  user = "backup";

  stagingScript = pkgs.writeShellApplication {
    name = "stage-mongodb-backup";
    runtimeInputs = with pkgs; [
      mongodb-tools
    ];
    text = builtins.readFile ./stage-mongodb.sh;
  };
in
{
  options.services.tik-backup.mongodb = {
    enable = (lib.mkEnableOption "backing up MongoDB Atlas databases") // {
      default = cfg.enable;
      defaultText = lib.literalExpression ''
        config.services.tik-backup.enable
      '';
    };
  };

  config = lib.mkIf cfg.mongodb.enable {
    assertions = [
      {
        assertion = cfg.mongodb.enable -> cfg.enable;
        message = ''
          `services.tik-backup.mongodb.enable` cannot be enabled without `services.tik-backup.enable`
        '';
      }
    ];

    sops = {
      secrets."mongodb/backup-uri" = {
        sopsFile = ../secrets/backup.yaml;
      };

      templates.mongodb-backup-config = {
        owner = user;
        content = ''
          uri: ${config.sops.placeholder."mongodb/backup-uri"}
        '';
      };
    };

    services.tik-backup = {
      stagingServices = [ "stage-mongodb.service" ];
      stagingSubdirs = [
        {
          inherit subdir user;
        }
      ];
    };

    systemd.services.stage-mongodb = {
      description = "Backup MongoDB Atlas databases";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      restartIfChanged = false;
      environment = {
        TARGET_DIR = "${cfg.stagingDir}/${subdir}";
        MONGO_CONFIG = config.sops.templates.mongodb-backup-config.path;
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe stagingScript}";
        User = user;
        Group = user;
      };
    };
  };
}
