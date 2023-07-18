{ lib, ... }:
with lib;
let
  loader = types.submodule {
    options = {
      readonly = mkOption {
        type = types.nullOr (types.enum [ "yes" "no" ]);
        default = null;
      };

      type = mkOption {
        type = types.nullOr (types.enum [ "rom" "pflash" ]);
        default = null;
      };

      secure = mkOption {
        type = types.nullOr (types.enum [ "yes" "no" ]);
        default = null;
        description = "Secure BOOT";
      };

      path = mkOption {
        type = types.path;
        description = "BIOS Path";
      };
    };
  };

  type = types.submodule {
    options = {
      arch = mkOption {
        type = types.nullOr types.str;
        description = ''
          arch specifying the CPU architecture to virtualization
          If arch is omitted then for most hypervisor drivers, the host native arch will be chosen
        '';
        default = null;
      };

      machine = mkOption {
        type = types.nullOr types.str;
        description = ''
          machine referring to the machine type. The Capabilities XML provides details on allowed values for these. 
        '';
        default = null;
        example = "pc-i440fx-5.1, q35";
      };

      content = mkOption {
        type = types.enum [ "hvm" "linux" ];
        description = ''
          hvm: full virt
          linux: Xen
        '';
        default = "hvm";
      };
    };
  };
in
{
  options = {
    type = mkOption {
      type = type;
      description = "os type";
      default = { };
    };

    firmware = mkOption {
      description = "System firmware";
      default = null;
      type = types.nullOr (types.enum [ "bios" "efi" ]);
    };

    loader = mkOption {
      description = "Loader Option";
      default = null;
      type = types.nullOr loader;
    };

    enableBootMenu = mkOption {
      description = "Boot Menu";
      default = false;
      type = types.bool;
    };

    bootOrder = mkOption {
      description = "Boot order";
      type = types.listOf (types.enum [
        "fd"
        "hd"
        "cdrom"
        "network"
      ]);
      default = [ "hd" "cdrom" ];
    };
  };
}
