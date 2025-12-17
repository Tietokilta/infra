{
  imports = [
    ./secrets/sops.nix
    ./discourse
    ./tikbots
    ./deployment.nix
    ./nginx.nix
    ./test-vm.nix
  ];
}
