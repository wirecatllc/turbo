{ lib, ... }:
with lib;
let
  driver = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = ''
          If the hypervisor supports multiple backend drivers, then the name attribute selects the primary backend driver name, while the optional type attribute provides the sub-type. For example, xen supports a name of "tap", "tap2", "phy", or "file", with a type of "aio", while qemu only supports a name of "qemu", but multiple types including "raw", "bochs", "qcow2", and "qed".
        '';
        default = "qemu";
      };

      type = mkOption {
        type = types.nullOr types.str;
        description = "see name";
        default = null;
        example = "qcow2";
      };
    };
  };

  source = types.submodule {
    options = {
      file = mkOption {
        type = types.nullOr types.path;
        description = "File Path";
      };
    };
  };

  target = types.submodule {
    options = {

      bus = mkOption {
        type = types.nullOr (types.enum [
          "ide"
          "scsi"
          "virtio"
          "xen"
          "usb"
          "sata"
          "sd"
        ]);
        description = ''
          If omitted, the bus type is inferred from the style of the device name (e.g. a device named 'sda' will typically be exported using a SCSI bus).
        '';
        default = null;
      };

      dev = mkOption {
        type = types.nullOr types.str;
        description = ''
          The dev attribute indicates the "logical" device name. The actual device name specified is not guaranteed to map to the device name in the guest OS. Treat it as a device ordering hint. 
        '';
        default = "vda";
      };
    };
  };

in
{
  options = {
    type = mkOption {
      type = types.enum [
        "file"
        "block"
        "dir"
        "network"
        "volume"
        "nvme"
        "vhostuser"
      ];
      description = "type";
      default = "file";
    };

    device = mkOption {
      type = types.enum [
        "floppy"
        "disk"
        "cdrom"
        "lun"
      ];
      description = "device type";
      default = "disk";
    };

    readonly = mkOption {
      type = types.nullOr types.bool;
      description = ''
        If present, this indicates the device cannot be modified by the guest. For now, this is the default for disks with attribute device='cdrom'.
      '';
      default = null;
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
  };
}
