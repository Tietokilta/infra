{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = {
    self,
    nixpkgs,
    devenv,
    systems,
    ...
  } @ inputs: let
    forEachSystem = nixpkgs.lib.genAttrs (import systems);
  in {
    packages = forEachSystem (system: {
      devenv-up = self.devShells.${system}.default.config.procfileScript;
      devenv-test = self.devShells.${system}.default.config.test;
    });

    devShells =
      forEachSystem
      (system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            {
              # https://devenv.sh/reference/options/
              packages = [pkgs.azure-cli];
              languages.terraform.enable = true;
              devcontainer = {
                enable = true;
                settings = {
                  updateContentCommand = "";
                  customizations.vscode.extensions = [
                    "mkhl.direnv"
                    "4ops.terraform"
                    "ms-azuretools.vscode-azureterraform"
                  ];
                };
              };

              git-hooks.hooks.terraform-fmt = {
                enable = true;
                name = "Terraform fmt check";
                entry = "terraform fmt --recursive";
                pass_filenames = false;
              };
            }
          ];
        };
      });
  };
}
