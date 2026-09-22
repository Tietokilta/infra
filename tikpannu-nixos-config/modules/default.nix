{
  imports = [
    ./secrets/sops.nix
    ./discourse
    ./tikbots
    ./umami
    ./deployment.nix
    ./nginx.nix
    ./test-vm.nix
    ./backup
  ];
}
