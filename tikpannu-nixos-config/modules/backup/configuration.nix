{
  services.tik-backup = {
    enable = true;
    azure.enable = true;
    storageboxServer = "u563055.your-storagebox.de";
    storageboxMountPath = "/mnt/backup";
    resticRepo = "/mnt/backup/restic-repo";
    stagingDir = "/mnt/backup/staging_dir";

    dates = [
      "04:00 Europe/Helsinki"
    ];

    retentionFlags = [
      "--keep-daily 7"
      "--keep-weekly 4"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt 0711 root root -" # backup user needs access to /mnt
  ];
}
