{ lib, ... }:
with lib;
let
  source = types.submodule {
    options = {
      mode = mkOption {
        type = types.enum [ "bind" "connect" ];
        default = "bind";
      };

      host = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      service = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
    };
  };
in
{
  options = {
    type = mkOption {
      type = types.enum [
        "tcp"
        "spicevmc"
      ];
      description = "type";
      default = "tcp";
    };

    bus = mkOption {
      type = types.enum [
        "usb"
      ];
      description = "bus";
      default = "usb";
    };

    source = mkOption {
      type = types.nullOr source;
      default = null;
    };
  };
}
