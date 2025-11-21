{
  pkgs,
  lib,
  config,
  ...
}:
let
  rebuild-from-infra = pkgs.writeShellScriptBin "rebuild-from-infra" ''
    ${lib.getExe config.system.build.nixos-rebuild} switch --flake github:Tietokilta/infra/"$1"
  '';
in
{
  users = {
    users.deploy = {
      isSystemUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByE/o9xtWGDllsqcw3ki5LD7r3lQOmlRPHYnsuflWnA"
      ];
      group = "deploy";
      packages = [ rebuild-from-infra ];
    };
    groups.deploy = { };
  };

  security.sudo.extraRules = [
    {
      users = [ "deploy" ];
      commands = [
        {
          command = "${lib.getExe rebuild-from-infra} *";
          options = [
            "SETENV"
            "NOPASSWD"
          ];
        }
      ];
    }
  ];
}
