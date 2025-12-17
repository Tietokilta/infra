{
  inputs,
  ...
}:
{
  imports = [
    inputs.tikbots.nixosModules.tikbots
    inputs.sops-nix.nixosModules.sops
  ];
}
