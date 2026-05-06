{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tik-backup;
  user = "azure-storage";
  blobSubdir = "azure-blob-storage";
  fileSubdir = "azure-file-storage";
  stagingScript = pkgs.writeShellApplication {
    name = "stage-azure-storages";
    runtimeInputs = with pkgs; [
      azure-cli
      azure-storage-azcopy
    ];
    text = builtins.readFile ./stage-storages.sh;
  };
in
{
  options.services.tik-backup.azure = {
    storage = {
      enable = (lib.mkEnableOption "backing up azure {file,blob} storage") // {
        default = cfg.azure.enable;
        defaultText = lib.literalExpression ''
          config.services.tik-backup.azure.enable
        '';
      };
    };
  };

  config = lib.mkIf cfg.azure.storage.enable {
    assertions = [
      {
        assertion = cfg.azure.storage.enable -> cfg.azure.enable;
        message = ''
          `services.tik-backup.azure.storage.enable` cannot be enabled without `services.tik-backup.azure.enable`
        '';
      }
    ];
    systemd.services."stage-azure-storages" = {
      description = "Stage Azure blob and file storage for backups";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      restartIfChanged = false;
      environment = {
        BLOB_DIR = "${cfg.stagingDir}/${blobSubdir}";
        FILE_DIR = "${cfg.stagingDir}/${fileSubdir}";
        AZURE_CLIENT_SECRET_FILE = config.sops.secrets."azure/backup-client-secret".path;
        HOME = "%t/azure-storages"; # needed for az login
      };
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.sops.templates.azure-storage-envfile.path;
        ExecStart = "${lib.getExe stagingScript}";
        User = user;
        Group = user;
        RuntimeDirectory = "azure-storages";
      };
    };
    sops = {
      secrets =
        lib.genAttrs
          [
            "azure/backup-client-secret"
            "azure/backup-client-id"
            "azure/backup-tenant-id"
          ]
          (_: {
            sopsFile = ../../secrets/backup.yaml;
            owner = user;
          });
      templates."azure-storage-envfile" = {
        owner = user;
        content = ''
          AZURE_CLIENT_ID=${config.sops.placeholder."azure/backup-client-id"}
          AZURE_TENANT_ID=${config.sops.placeholder."azure/backup-tenant-id"}
        '';
      };
    };
    services.tik-backup = {
      stagingServices = [ "stage-azure-storages.service" ];
      stagingSubdirs = [
        {
          inherit user;
          subdir = blobSubdir;
          clean = false;
        }
        {
          inherit user;
          subdir = fileSubdir;
          clean = false;
        }
      ];
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
