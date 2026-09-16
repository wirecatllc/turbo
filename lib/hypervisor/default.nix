{ pkgs, ... }:
let
  images = import ./images.nix { inherit pkgs; };
in
images // (import ./cloud-init.nix { inherit pkgs; }) // {
  isos = images.isos // {
    nixos = import ./nixos.nix { inherit pkgs; };
  };
}
