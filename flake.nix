{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    tikbots = {
      url = "github:Tietokilta/tikbots";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      systems,
      ...
    }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      nixosConfigurations.tikpannu = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./tikpannu-nixos-config/configuration.nix ];
      };

      checks = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
          import ./tikpannu-nixos-config/tests { inherit pkgs inputs; }
      );

      devShells = forEachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              (azure-cli.withExtensions [
                azure-cli-extensions.ssh
              ])
              sops
              terraform
            ];

            shellHook = ''
              if [ ! -x .git/hooks/pre-commit ] ; then
                ./setup-pre-commit.sh
              fi
            '';
          };
        }
      );
    };
}
