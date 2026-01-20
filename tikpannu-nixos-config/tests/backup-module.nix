{ lib, pkgs, ... }:
let
  mockResticPassFile = pkgs.writeText "mock-restic-pass" "test-restic-password";
in
{
  name = "backup-module";

  nodes = {
    pannu =
      { config, inputs, ... }:
      {
        imports = [
          inputs.sops-nix.nixosModules.sops
          ../modules/backup
        ];

        virtualisation = {
          memorySize = 2048;
          cores = 2;
        };

        # Configure sops to use a generated test key
        sops = {
          age.keyFile = "/etc/age-test-key";
          age.generateKey = false;
        };

        # Enable backup with mock storage
        services.tik-backup = {
          enable = true;
          storageboxServer = "mock.storagebox.local";
          # Use local path instead of CIFS for testing.
          # Avoid /tmp because restic services run with PrivateTmp.
          backupPath = "/mnt/backup-test/restic-repo";
          mountPath = "/mnt/backup-test";
        };

        # Override restic password file to bypass sops
        services.restic.backups.tik-base.passwordFile = lib.mkForce mockResticPassFile.outPath;

        # Don't actually mount CIFS - just create the directory
        fileSystems."/mnt/backup-test" = lib.mkForce {
          device = "none";
          fsType = "tmpfs";
          options = [
            "defaults"
            "size=100M"
            "mode=755"
          ];
        };

        # Provide a dummy age key file so sops-nix doesn't fail
        environment.etc."age-test-key".text = ''
          # AGE-SECRET-KEY-1DUMMY
        '';

        # Disable sops secret activation (we're using mock files directly)
        sops.secrets.storagebox-credentials.restartUnits = lib.mkForce [ ];
        sops.secrets.backup-restic-password.restartUnits = lib.mkForce [ ];

        system.stateVersion = "23.11";
      };
  };

  testScript = ''
    start_all()

    # Wait for system to be ready
    pannu.wait_for_unit("multi-user.target")

    # Debug: check what filesystems exist
    pannu.succeed("mount | grep backup || true")
    pannu.succeed("ls -la /mnt/ || true")

    # Create backup directory if mount didn't work
    pannu.succeed("mkdir -p /mnt/backup-test")

    # Verify backup staging directory exists
    pannu.succeed("test -d /var/backup")

    # Verify restic service is configured
    pannu.succeed("systemctl cat restic-backups-tik-base.service")

    # Verify timer is configured
    pannu.succeed("systemctl cat restic-backups-tik-base.timer")

    # Test restic repository initialization by running the backup service
    pannu.succeed("systemctl start restic-backups-tik-base.service")

    # Verify repository was created
    pannu.succeed("test -d /mnt/backup-test/restic-repo")

    # Verify the service completed successfully (oneshot services go inactive after success)
    pannu.succeed("systemctl show -p ActiveState restic-backups-tik-base.service | grep -q inactive")

    print("Backup module tests passed!")
  '';
}
