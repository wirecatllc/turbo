{ lib, ... }:
with lib;
let
  source = types.submodule {
    options = {
      path = mkOption {
        type = types.nullOr types.path;
        description = "path";
        default = null;
        example = "/dev/pts/4";
      };
    };
  };


  target = types.submodule {
    options = {
      type = mkOption {
        type = types.nullOr (types.enum [
          "serial"
          "virtio"
          "xen"
          "lxc"
          "openvz"
          "sclp"
          "sclplm"
        ]);
        description = ''
          serial (described below); virtio (usable whenever VirtIO support is available); xen, lxc and openvz (available when the corresponding hypervisor is in use). sclp and sclplm (usable for s390 and s390x QEMU guests) are supported for compatibility reasons but should not be used for new guests: use the sclpconsole and sclplmconsole target models, respectively, with the serial element instead.
        '';
        default = "serial";
      };
      port = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "0";
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

    source = mkOption {
      type = types.nullOr source;
      description = "sub source resource";
      default = null;
    };

    target = mkOption {
      type = types.nullOr target;
      default = null;
    };
  };
}
