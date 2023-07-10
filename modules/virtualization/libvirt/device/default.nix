{ lib, ... }:
with lib;
let
  supportedDevices = {
    input = ./input.nix;
    graphics = ./graphics.nix;
    disk = ./disk.nix;
    filesystem = ./filesystem.nix;
    interface = ./interface.nix;
    hostdev = ./hostdev.nix;
    console = ./console.nix;
    serial = ./serial.nix;
    video = ./video.nix;
    redirdev = ./redirdev.nix;
  };

  modules = attrsets.mapAttrs
    (n: v: mkOption {
      type = types.attrsOf (types.submodule v);
      description = n;
      default = { };
    })
    supportedDevices;

in
{
  options = {
    extraConfig = mkOption {
      type = types.str;
      description = "XML to insert";
      default = "";
    };
  } // modules;
}
