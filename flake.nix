{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };

    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, ... }:
    let
      turboOptions = import ./modules;
      supportedSystems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
      
      # A la carte
      nixosModules = {
        networking = ./modules/networking;
        storage = ./modules/storage;
        virtualization = ./modules/virtualization;
      };
    in utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      # All modules
      nixosModule = ./modules;

      packages = 
      {
         # Manual
        manual =
          let
            getModuleDoc = turboOptions: (pkgs.nixosOptionsDoc {
              inherit (pkgs.lib.evalModules {
                specialArgs = { inherit pkgs; };
                modules = [ turboOptions suppressModuleArgsDocs ];
              }) options;
              warningsAreErrors = false;
            }).optionsCommonMark;

            suppressModuleArgsDocs = { lib, ... }: {
              options = {
                _module.args = lib.mkOption {
                  internal = true;
                };
              };

              config = {
                _module.check = false;
              };
            };
            optionsMd = pkgs.lib.mapAttrs (k: v: 
              getModuleDoc v
            ) nixosModules;
          in
          pkgs.callPackage ./docs {
            inherit optionsMd;
          };
      };
      # Dev Shell
      devShell = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = [
          nixpkgs.legacyPackages.${system}.nixpkgs-fmt
        ];
      };
    }) // nixosModules; # Non-each system related items
}
