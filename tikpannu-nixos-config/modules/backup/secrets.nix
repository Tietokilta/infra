{
  config,
  lib,
  ...
}:
let
  cfg = config.services.tik-backup;
in
{
  sops.secrets = lib.mkIf cfg.enable {
    storagebox-credentials = {
      sopsFile = ../secrets/backup.yaml;
      # CIFS credentials file format: username=uXXXXXX\npassword=PASSWORD
    };

    restic-password = {
      sopsFile = ../secrets/backup.yaml;
      owner = "backup";
    };
  };
}
