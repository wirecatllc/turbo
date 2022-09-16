{ lib, ... }:
with lib;
let
  listen = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [
          "address"
          "socket"
        ];
        description = "type";
      };

      socket = mkOption {
        type = types.nullOr types.path;
        description = "socket path";
        default = null;
        example = "/run/hypervisor/vnc/server-1";
      };
    };
  };
in
{
  options = {
    type = mkOption {
      type = types.nullOr (types.enum [
        "sdl"
        "vnc"
        "spice"
        "rdp"
        "desktop"
        "egl-headless"
      ]);
      description = "type";
      default = null;
    };

    listen = mkOption {
      type = types.nullOr listen;
      default = null;
    };
  };
}
