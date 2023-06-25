{ lib, ... }:
with lib;
{
  options = {
    cpuMode = mkOption {
        type = types.enum [ "host-passthrough" "host-model" "qemu64" ];
        default = "qemu64";
        description = ''
            which mode to passthru CPU model, these are some presets
        '';
    };

    customConfig = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
            XML settings for <cpu> section, direct replace. See https://libvirt.org/formatdomain.html#cpu-model-and-topology
        '';
    };
  };
}
