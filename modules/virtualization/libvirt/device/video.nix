{ lib, ... }:
with lib;
let
  model = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [
          "virtio"
          "vga"
          "ramfb"
          "qxl"
          "none"
          "bochs"
        ];
        description = "type";
        default = "virtio";
      };

      "3daccel" = mkOption {
        type = types.nullOr types.bool;
        description = "enable 3d acceleration, only available for virtio";
        default = null;
        example = true;
      };
    };
  };

in
{
  options = {
    model = mkOption {
      type = types.nullOr model;
      default = null;
    };
  };
}
