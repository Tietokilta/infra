{
  pkgs,
  inputs,
}:
let
  runTest =
    testPath:
    pkgs.testers.runNixOSTest {
      imports = [
        testPath
        {
          node.specialArgs = { inherit inputs; };
        }
      ];
    };
in
{
  server-up = runTest ./server-up.nix;
}
