{
  imports = [
    ./storagebox.nix
    ./secrets.nix
  ];

  services.tik-backup = {
    enable = true;
    storageboxServer = "u563055.your-storagebox.de";
  };
}
