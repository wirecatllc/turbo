{ lib, ... }:
with lib;
let
  target = types.submodule {
    options = {
      dev = mkOption {
        type = types.str;
        description = ''
          device name
        '';
        example = "v-server";
      };

      managed = mkOption {
        type = types.nullOr (types.enum [ "yes" "no" ]);
        description = ''
          managed attr
        '';
        default = null;
      };
    };
  };

  source = types.submodule {
    options = {
      bridge = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Bridged Interface";
      };
    };
  };

  model = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "virtio" ];
        description = "";
        default = "virtio";
      };
    };
  };

  mac = types.submodule {
    options = {
      address = mkOption {
        type = types.str;
        description = "device mac address";
        example = "52:54:00:5d:c7:9e";
      };
    };
  };
in
{
  options = {
    type = mkOption {
      type = types.nullOr (types.enum [
        "ethernet"
        "network"
        "direct"
        "bridge"
        "user"
      ]);
      description = "input type";
      default = null;
    };

    managed = mkOption {
      type = types.nullOr (types.enum [ "yes" "no" ]);
      description = ''
        managed attr
      '';
      default = null;
    };

    source = mkOption {
      type = types.nullOr source;
      default = null;
    };

    model = mkOption {
      type = types.nullOr model;
      default = null;
    };

    mac = mkOption {
      type = types.nullOr mac;
      default = null;
    };

    target = mkOption {
      type = types.nullOr target;
      default = null;
    };
  };
}
