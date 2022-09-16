{ lib, ... }:
with lib;
let
  source = types.submodule {
    options = {
      dev = mkOption {
        type = types.nullOr types.path;
        description = ''
          boot device
        '';
        default = null;
      };

      grab = mkOption {
        type = types.nullOr (types.enum [ "all" ]);
        description = ''
          attributes grab with value 'all' which when enabled grabs all input devices instead of just one
        '';
        default = null;
      };

      repeat = mkOption {
        type = types.nullOr (types.enum [ "on" "off" ]);
        description = ''
          repeat with value 'on'/'off' to enable/disable auto-repeat events 
        '';
        default = null;
      };

      grabToggle = mkOption {
        type = types.nullOr (types.enum [ "ctrl-ctrl" "alt-alt" "shift-shift" "meta-meta" "scrolllock" "ctrl-scrolllock" ]);
        description = ''
          change the grab key combination
        '';
        default = null;
      };
    };
  };
in
{
  options = {
    type = mkOption {
      type = types.nullOr (types.enum [
        "mouse"
        "tablet"
        "keyboard"
        "passthrough"
        "evdev"
      ]);
      description = "input type";
      default = null;
    };

    bus = mkOption {
      type = types.nullOr (types.enum [
        "xen"
        "ps2"
        "usb"
        "virtio"
      ]);
      description = "input bus";
      default = null;
    };


    source = mkOption {
      type = types.nullOr source;
      description = "sub source resource";
      default = null;
    };
  };
}
