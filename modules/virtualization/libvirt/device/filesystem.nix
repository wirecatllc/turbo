{ lib, ... }:
with lib;
let
  lock = types.submodule {
    options = {
      posix = mkOption {
        type = types.enum [ "on" "off" ];
        default = "off";
      };

      flock = mkOption {
        type = types.enum [ "on" "off" ];
        default = "off";
      };
    };
  };

  binary = types.submodule {
    options = {
      path = mkOption {
        type = types.path;
      };

      xattr = mkOption {
        type = types.nullOr types.str;
        default = "on";
      };

      cacheMode = mkOption {
        type = types.enum [ "none" "always" ];
        default = "always";
      };

      lock = mkOption {
        type = lock;
        default = { };
      };
    };
  };

  driver = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [
          "path"
          "loop"
          "virtiofs"
        ];
        description = "input type";
      };

      format = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "raw";
      };
    };
  };

  source = types.submodule {
    options = {
      file = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/export/to/guest.img";
      };

      dir = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/path";
      };

      socket = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/tmp/sock";
      };
    };
  };

  target = types.submodule {
    options = {
      dir = mkOption {
        type = types.str;
        example = "/import/from/host";
      };
    };
  };
in
{
  options = {
    type = mkOption {
      type = types.nullOr (types.enum [
        "mount"
        "file"
        "block"
        "ram"
        "bind"
      ]);
      description = "input type";
      default = null;
    };

    accessmode = mkOption {
      type = types.enum [
        "passthrough"
        "mapped"
        "squash"
      ];
      description = "Access mode";
      default = "mapped";
    };

    readonly = mkOption {
      type = types.bool;
      description = "Is media read only";
      default = false;
    };

    driver = mkOption {
      type = types.nullOr driver;
      default = null;
    };

    source = mkOption {
      type = types.nullOr source;
      default = null;
    };

    target = mkOption {
      type = types.nullOr target;
      default = null;
    };

    binary = mkOption {
      type = types.nullOr binary;
      default = null;
    };
  };
}
