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
      self,
      nixpkgs,
      systems,
      ...
    }@inputs:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          f (
            import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            }
          )
        );
    in
    {
      nixosConfigurations.tikpannu = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./tikpannu-nixos-config/configuration.nix ];
      };

      checks = forAllSystems (
        pkgs:
        {
          formatting =
            pkgs.runCommand "fmt-check"
              {
                nativeBuildInputs = [ self.formatter.${pkgs.stdenv.hostPlatform.system} ];
              }
              ''
                cp -r ${self} repo
                chmod -R +w repo/
                treefmt --ci --tree-root repo
                touch $out
              '';
        }
        // (import ./tikpannu-nixos-config/tests { inherit pkgs inputs; })
      );

      formatter = forAllSystems (
        pkgs:
        pkgs.treefmt.withConfig {
          runtimeInputs = with pkgs; [
            nixfmt
            opentofu
            yamlfmt
          ];

          settings.formatter = {
            nix = {
              command = "nixfmt";
              includes = [ "*.nix" ];
            };
            terraform = {
              command = "tofu";
              options = [ "fmt" ];
              includes = [ "*.tf" ];
            };
            yaml = {
              command = "yamlfmt";
              includes = [
                "*.yaml"
                "*.yml"
              ];
            };
          };
        }
      );

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            (azure-cli.withExtensions [
              azure-cli-extensions.ssh
            ])
            sops
            terraform
          ];

          shellHook = ''
            if ! cmp --silent .git/hooks/pre-commit .pre-commit-hook.sh ; then
              ./setup-pre-commit.sh
            fi
          '';
        };
      });
    };
}
