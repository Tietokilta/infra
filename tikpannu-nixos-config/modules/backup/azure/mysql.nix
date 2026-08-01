{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.tik-backup;
  subdir = "azure-mysql";
  user = "backup";

  stagingScript = pkgs.writeShellApplication {
    name = "stage-azure-mysql-backup";
    runtimeInputs = with pkgs; [
      mysql84
    ];
    text = builtins.readFile ./stage-mysql.sh;
  };
in
{
  options.services.tik-backup.azure = {
    mysql = {
      enable = (lib.mkEnableOption "backing up mysql databases") // {
        default = cfg.azure.enable;
        defaultText = lib.literalExpression ''
          config.services.tik-backup.azure.enable
        '';
      };
    };
  };

  config = lib.mkIf cfg.azure.mysql.enable {
    assertions = [
      {
        assertion = cfg.azure.mysql.enable -> cfg.azure.enable;
        message = ''
          `services.tik-backup.azure.mysql.enable` cannot be enabled without `services.tik-backup.azure.enable`
        '';
      }
    ];

    sops = {
      secrets =
        lib.genAttrs
          [
            "azure/mysqluser"
            "azure/mysqlhost"
            "azure/mysqlpass"
          ]
          (_: {
            sopsFile = ../../secrets/backup.yaml;
          });

      templates.azure-mysql-cnf = {
        owner = user;
        content = ''
          [client]
          host = ${config.sops.placeholder."azure/mysqlhost"}
          user = ${config.sops.placeholder."azure/mysqluser"}
          password = ${config.sops.placeholder."azure/mysqlpass"}
          ssl-mode = REQUIRED
        '';
      };
    };

    services.tik-backup = {
      stagingServices = [ "stage-azure-mysql.service" ];
      stagingSubdirs = [
        {
          inherit subdir user;
        }
      ];
    };

    systemd.services.stage-azure-mysql = {
      description = "Backup Azure mysql databases";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      restartIfChanged = false;
      environment = {
        TARGET_DIR = "${cfg.stagingDir}/${subdir}";
        MYSQL_CNF = config.sops.templates.azure-mysql-cnf.path;
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
