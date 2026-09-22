{
  config,
  pkgs,
  lib,
  ...
}:
let
  enable = config.services.umami.enable && config.services.tik-backup.enable;
  stagingDir = config.services.tik-backup.stagingDir;
  tmpDir = "/tmp/umami-backup-snapshot";
  subdir = "umami";

  dumpToTmp = pkgs.writeShellApplication {
    name = "stage-umami-backup-1";
    runtimeInputs = [
      config.services.postgresql.package
      pkgs.acl
    ];
    text = ''
      set -euo pipefail

      rm -rf "${tmpDir}"
      mkdir -m 700 "${tmpDir}"
      pg_dump --format=custom --file="${tmpDir}/umami.dump" umami
      setfacl -Rm u:backup:rwX "${tmpDir}"
    '';
  };

  stagingScript = pkgs.writeShellApplication {
    name = "stage-umami-backup-2";
    text = ''
      set -euo pipefail

      cp "${tmpDir}"/* "${stagingDir}/${subdir}/"
      rm -rf "${tmpDir}"/*
    '';
  };
in
{
  config = lib.mkIf enable {
    services.tik-backup = {
      stagingServices = [
        "umami-stage-backup1.service"
        "umami-stage-backup2.service"
      ];
      stagingSubdirs = [
        {
          inherit subdir;
        }
      ];
    };

    systemd.services = {
      umami-stage-backup1 = {
        description = "Dump the umami database to /tmp for the backup user";
        restartIfChanged = false;
        requires = [ "postgresql.target" ];
        after = [ "postgresql.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "postgres";
          ExecStart = lib.getExe dumpToTmp;
        };
      };
      umami-stage-backup2 = {
        description = "Stage umami database dump to ${stagingDir}";
        requires = [ "umami-stage-backup1.service" ];
        after = [ "umami-stage-backup1.service" ];
        restartIfChanged = false;
        serviceConfig = {
          Type = "oneshot";
          User = "backup";
          ExecStart = lib.getExe stagingScript;
        };
      };
    };
  };
}
