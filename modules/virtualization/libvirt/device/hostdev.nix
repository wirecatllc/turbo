# boot.kernelParams = [ "vfio-pci.ids=10de:13aa,10de:1ec7,10de:10f8,10de:1ad8,10de:1ad9" ];
# https://github.com/mars-research/redleaf/blob/master/rebind-82599es.sh
# Hot rebind device

{ lib, ... }:
with lib;
let
  rom = types.submodule {
    options = {
      bar = mkOption {
        type = types.enum [
          "on"
          "off"
        ];
        description = "bar";
        default = "on";
      };

      file = mkOption {
        type = types.nullOr types.path;
        description = "socket path";
      };
    };
  };

  address = types.submodule {
    options = {
      domain = mkOption {
        type = types.str;
        default = "0x0000";
      };
      bus = mkOption {
        type = types.str;
        example = "0x06";
      };
      slot = mkOption {
        type = types.str;
        example = "0x02";
      };

      function = mkOption {
        type = types.str;
        example = "0x0";
      };
    };
  };

  source = types.submodule {
    options = {
      writeFiltering = mkOption {
        type = types.nullOr (types.enum [ "yes" "no" ]);
        default = null;
      };

      address = mkOption {
        type = address;
      };
    };
  };
in
{
  options = {
    type = mkOption {
      type = types.enum [
        "pci"
      ];
      description = "type";
      default = "pci";
    };

    managed = mkOption {
      type = types.nullOr (types.enum [
        "yes"
        "no"
      ]);
      description = "type";
      default = "yes";
    };


    mode = mkOption {
      type = types.enum [
        "subsystem"
      ];
      description = "mode";
      default = "subsystem";
    };

    source = mkOption {
      type = source;
    };

    rom = mkOption {
      type = types.nullOr rom;
      default = null;
    };
  };
}
