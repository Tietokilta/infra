{
  imports = [
    ./storagebox.nix
    ./secrets.nix
  ];

  services.tik-backup = {
    enable = true;
    storageboxServer = "u531035.your-storagebox.de";
  };
}
