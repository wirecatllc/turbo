{ lib, ... }:
with lib;
{
  options = {
    size = mkOption {
      type = types.ints.unsigned;
      description = ''
        The content of this element defines the maximum number of virtual CPUs allocated for the guest OS, which must be between 1 and the maximum supported by the hypervisor.
      '';
      default = 1;
    };

    placement = mkOption {
      type = types.nullOr (types.enum [ "static" "auto" ]);
      description = ''
        The optional attribute placement can be used to indicate the CPU placement mode for domain process. 
      '';
      default = null;
    };

    cpuset = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The optional attribute cpuset is a comma-separated list of physical CPU numbers that domain process and virtual CPUs can be pinned to by default. 
      '';
      example = "1-4,^3,6";
    };

    current = mkOption {
      type = types.nullOr types.ints.unsigned;
      default = null;
      description = ''
        The optional attribute current can be used to specify whether fewer than the maximum number of virtual CPUs should be enabled. Since 0.8.5
      '';
    };
  };
}
