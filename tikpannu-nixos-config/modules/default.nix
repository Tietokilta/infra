{
  imports = [
    ./secrets/sops.nix
    ./discourse
    ./tikbots
    ./umami
    ./deployment.nix
    ./gatus.nix
    ./nginx.nix
    ./test-vm.nix
    ./backup
  ];
}
