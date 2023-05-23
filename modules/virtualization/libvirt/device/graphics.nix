{ lib, ... }:
with lib;
let
  listen = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [
          "address"
          "socket"
          "none"
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

  opengl = types.submodule {
    options = {
      enable = mkOption {
        type = types.enum [
          "yes"
          "no"
        ];

        description = "enable opengl";
      };

      rendernode = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/dev/dri/by-path/pci-0000:50:00.0-render";
        description = "Which driver to use, leave null to be in auto mode";
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

    opengl = mkOption {
      type = types.nullOr opengl;
      default = null;
    };
  };
}
