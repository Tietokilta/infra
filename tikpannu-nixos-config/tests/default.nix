{
  pkgs,
  inputs,
}:
let
  lib = pkgs.lib;
  runTest = testPath:
    pkgs.testers.runNixOSTest {
      imports = [
        (lib.modules.importApply testPath { inherit inputs; })
      ];
    };
in
{
  server-up = runTest ./server-up.nix;
}
