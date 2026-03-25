{
  lib,
  pkgs,
  ...
}:
{
  name = "restic-backups";

  nodes.pannu = {
    imports = [
      ./base-pannu-config.nix
    ];

    services.tik-backup.enable = lib.mkForce true;

    # Enable discourse for the backup logic, not to run it
    services.discourse.enable = lib.mkForce true;
    systemd.services.discourse.wantedBy = lib.mkForce [ ];

    systemd.tmpfiles.rules = [
      "d /mnt/backup 0700 backup backup -"
      "d /var/lib/discourse/backups/default 0700 discourse discourse -"
      ""
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
    stdout = pannu.succeed(''''
      cd /var/lib/discourse/backups/default;
      gzip <<< "" > dump.sql.gz;
      mkdir dir && touch dir/deepfile;
      tar czf dummy.tar.gz --exclude=dummy.tar.gz .;
      touch -md @0 dummy.tar.gz;
      chown -R discourse:discourse .;
    '''')

    pannu.succeed("systemctl start restic-backups-tik-backup.service")
    unit_succeeded("discourse-stage-backup.service")

    _, stdout = pannu.execute("restic-tik-backup ls latest")
    print("Backed up files:")
    print(stdout)

    # At least min_files files must exist in the backup. This does not include
    # directories.
    min_files = 1
    stdout = pannu.succeed(f''''
      restic-tik-backup ls --json latest \\
      | jq --exit-status --slurp \\
        '[.[] | select(.type=="file")] | length | select(. >= {min_files})'
    '''')
    print(f"Found {stdout.strip()} files")
  '';
}
