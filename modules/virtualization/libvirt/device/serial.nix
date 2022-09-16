{ lib, ... }:
with lib;
let
  target = types.submodule {
    options = {
      type = mkOption {
        type = types.nullOr (types.enum [
          "system-serial"
          "isa-serial"
        ]);
        default = "isa-serial";
      };

      port = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "0";
      };

      model = mkOption {
        type = types.nullOr model;
        default = null;
      };
    };
  };

  model = types.submodule {
    options = {
      name = mkOption {
        type = types.nullOr (types.enum [
          "isa-serial"
          "16550a"
        ]);
        default = "isa-serial";
      };
    };
  };
in
{
  options = {
    type = mkOption {
      type = types.nullOr (types.enum [
        "pty"
      ]);
      description = "input type";
      default = "pty";
    };

    target = mkOption {
      type = types.nullOr target;
      default = null;
    };
  };
}
