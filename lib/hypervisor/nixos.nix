{ pkgs }:
extraConfig:
let
  evaluated = pkgs.nixos ({ lib, modulesPath, ... }: {
    imports = [
      (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
      (modulesPath + "/installer/cd-dvd/channel.nix")
      extraConfig
    ];

    documentation.enable = lib.mkDefault false;
    documentation.man.enable = lib.mkDefault false;
    documentation.doc.enable = lib.mkDefault false;
    documentation.nixos.enable = lib.mkDefault false;
  });
  config = evaluated.config;
  # Newer nixpkgs exposes the complete relative path, including compression.
  imagePath = config.image.filePath or
    ("iso/${config.isoImage.isoName}"
      + pkgs.lib.optionalString config.isoImage.compressImage ".zst");
in
"${config.system.build.isoImage}/${imagePath}"
