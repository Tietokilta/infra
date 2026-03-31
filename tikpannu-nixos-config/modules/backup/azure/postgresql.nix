{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.tik-backup;
  subdir = "azure-psql";
  user = "azure-psql";

  stagingScript = pkgs.writeShellApplication {
    name = "stage-azure-psql-backup";
    runtimeInputs = with pkgs; [
      postgresql
    ];
    text = builtins.readFile ./stage-postgresql.sh;
  };
in
{
  options.services.tik-backup.azure = {
    postgresql = {
      enable = (lib.mkEnableOption "backing up postgresql databases") // {
        default = cfg.azure.enable;
        defaultText = lib.literalExpression ''
          config.services.tik-backup.azure.enable
        '';
      };
    };
  };

  config = lib.mkIf cfg.azure.postgresql.enable {
    assertions = [
      {
        assertion = cfg.azure.postgresql.enable -> cfg.azure.enable;
        message = ''
          `services.tik-backup.azure.postgresql.enable` cannot be enabled without `services.tik-backup.azure.enable`
        '';
      }
    ];

    sops = {
      secrets =
        lib.genAttrs
          [
            "azure/pguser"
            "azure/pghost"
            "azure/pgpass"
          ]
          (name: {
            sopsFile = ../../secrets/backup.yaml;
          });
      templates.azure-psql-envfile = {
        owner = user;
        content = ''
          PGUSER=${config.sops.placeholder."azure/pguser"}
          PGHOST=${config.sops.placeholder."azure/pghost"}
          PGPASSWORD=${config.sops.placeholder."azure/pgpass"}
        '';
      };
    };

    services.tik-backup = {
      stagingServices = [ "stage-azure-psql.service" ];
      stagingSubdirs = [
        {
          inherit subdir user;
        }
      ];
    };

    systemd.services.stage-azure-psql = {
      description = "Backup Azure postgresql databases";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.sops.templates.azure-psql-envfile.path;
        ExecStart = ''${lib.getExe stagingScript} "${cfg.stagingDir}/${subdir}/"'';
        User = user;
        Group = user;
      };
    };

    users = {
      users.${user} = {
        isSystemUser = true;
        group = user;
      };
      groups.${user} = { };
    };
  };
}
