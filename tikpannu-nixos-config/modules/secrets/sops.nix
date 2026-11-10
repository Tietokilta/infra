{
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Secrets used by several modules, such as the Gatus heartbeat token.
  # Secrets belonging to a single service go in their own file.
  sops.defaultSopsFile = ./default.yaml;
}
