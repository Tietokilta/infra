{
  services.tik-backup = {
    enable = true;
    storageboxServer = "u563055.your-storagebox.de";
    storageboxMountPath = "/mnt/backup";
    stagingDir = "/var/lib/backup";

    dates = [
      "04:00"
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
