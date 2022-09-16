{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {

    # All modules
    nixosModule = ./modules;

    # A la carte
    nixosModules = {
      networking = ./modules/networking;
      storage = ./modules/storage;
      virtualization = ./modules/virtualization;
    };
  };
}
