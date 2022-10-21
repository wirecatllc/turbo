{ lib, config, ... }:
with builtins;
let
  cfg = config.turbo.networking.rename-interfaces;
  types = lib.types;
in
{
  imports = [
    ./udev.nix
    ./networkd.nix
  ];

  options = {
    turbo.networking.rename-interfaces = {
      enable = lib.mkOption {
        description = "Rename network interfaces based on MAC address";
        type = types.bool;
        default = false;
      };
      interfaces = lib.mkOption {
        description = "Interfaces";
        type = types.attrsOf types.str;
      };
      method = lib.mkOption {
        description = "Method to rename the interfaces";
        type = types.enum [ "udev" "networkd" ];
        default = "networkd";
      };
    };
  };
}
