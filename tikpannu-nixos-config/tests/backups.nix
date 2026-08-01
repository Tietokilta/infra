{
  lib,
  pkgs,
  config,
  ...
}:
{
  name = "restic-backups";

  nodes.pannu = {
    imports = [
      ./base-pannu-config.nix
    ];

    services.tik-backup = {
      enable = lib.mkForce true;
      azure.enable = lib.mkForce true;
      azure.postgresql.enable = lib.mkForce true;
      azure.mysql.enable = lib.mkForce true;
    };

    # PostgreSQL, MySQL, restic and discourse's config all in one VM.
    virtualisation.memorySize = 2048;
    virtualisation.diskSize = 4096;

    # Enable a local PostgreSQL server and create mock DBs for the test VM.
    services.postgresql = {
      enable = lib.mkForce true;
      ensureDatabases = [
        "mock1"
        "mock2"
        "mock3"
      ];
      ensureUsers = [
        {
          name = "azure-psql-backup";
          ensureClauses = {
            password = "verygoodpass";
          };
        }
      ];
    };

    systemd.services.stage-azure-psql = {
      requires = [ "postgresql.target" ];
      after = [ "postgresql.target" ];
      serviceConfig.EnvironmentFile = lib.mkForce (
        pkgs.writeText "envfile" ''
          PGHOST=127.0.0.1
          PGUSER=azure-psql-backup
          PGPASSWORD=verygoodpass
        ''
      );
    };

    # Enable a local MySQL server and create mock DBs for the test VM.
    # `ensureUsers` creates auth_socket users for non-MariaDB, so the
    # password-authenticated backup user has to come from `initialScript`.
    services.mysql = {
      enable = true;
      package = pkgs.mysql84;
      initialScript = pkgs.writeText "mysql-init.sql" ''
        CREATE DATABASE mock1;
        CREATE DATABASE mock2;
        CREATE DATABASE mock3;
        CREATE TABLE mock1.things (id INT PRIMARY KEY, name VARCHAR(32));
        INSERT INTO mock1.things VALUES (1, 'hello');
        CREATE USER 'mysql-backup'@'%' IDENTIFIED BY 'verygoodpass';
        GRANT SELECT, SHOW VIEW, TRIGGER, EVENT ON *.* TO 'mysql-backup'@'%';
      '';
    };

    systemd.services.stage-azure-mysql = {
      requires = [ "mysql.service" ];
      after = [ "mysql.service" ];
      # ssl-mode stays REQUIRED even over loopback: MySQL 8.4 defaults to
      # caching_sha2_password, which refuses password auth on an insecure
      # channel, and TCP to 127.0.0.1 does not count as one. mysqld's
      # --initialize-insecure generates a self-signed cert, and REQUIRED does no
      # CA or hostname verification, so this exercises the same path as prod.
      environment.MYSQL_CNF = lib.mkForce (
        toString (
          pkgs.writeText "mysql.cnf" ''
            [client]
            host = 127.0.0.1
            user = mysql-backup
            password = verygoodpass
            ssl-mode = REQUIRED
          ''
        )
      );
    };

    # Enable discourse for the backup logic, not to run it
    services.discourse.enable = lib.mkForce true;
    systemd.services.discourse.wantedBy = lib.mkForce [ ];

    systemd.tmpfiles.rules = [
      "d /mnt/backup 0700 backup backup -"
      "d /var/lib/discourse/backups/default 0700 discourse discourse -"
    ];

    environment.systemPackages = [
      pkgs.jq
    ];
  };

  testScript = /* python */ ''
    def unit_succeeded(unit_name: str):
      # Check that the unit actually ran
      _, exit_time = pannu.execute(
        f"systemctl show -p ExecMainExitTimestamp --value '{unit_name}'"
      )
      _, result = pannu.execute(
        f"systemctl show -p Result --value '{unit_name}'"
      )
      assert exit_time.strip() != "", f"Unit {unit_name} never ran"
      assert result.strip() == "success", f"Unit {unit_name} did not succeed, got {result}"

    start_all()

    # Discourse staging service only uses files that have been modified more
    # than some minutes ago.
    discourse_dummy = "/var/lib/discourse/backups/default/dummy_backup.tar.gz"
    pannu.succeed(f''''
      touch -m -d @0 {discourse_dummy} && \\
        chown discourse:discourse {discourse_dummy}
    '''')

    pannu.succeed("systemctl start restic-backups-tik-backup.service")
    unit_succeeded("discourse-stage-backup2.service")
    unit_succeeded("stage-azure-psql.service")
    unit_succeeded("stage-azure-mysql.service")

    pannu.succeed(
      "restic-tik-backup dump latest "
      "${config.nodes.pannu.services.tik-backup.stagingDir}/azure-mysql/mock1.sql "
      "| grep -q 'INSERT INTO'"
    )

    # Backup user must be able to clean up this dir
    pannu.succeed("sudo -u backup sh -c 'rm -rf ${config.nodes.pannu.services.tik-backup.stagingDir}/*'")

    _, stdout = pannu.execute("restic-tik-backup ls latest")
    print("Backed up files:")
    print(stdout)

    # At least min_files files must exist in the backup. This does not include
    # directories.
    min_files = 7
    stdout = pannu.succeed(f''''
      restic-tik-backup ls --json latest \\
      | jq --exit-status --slurp \\
        '[.[] | select(.type=="file")] | length | select(. >= {min_files})'
    '''')
    print(f"Found {stdout.strip()} files")
  '';
}
