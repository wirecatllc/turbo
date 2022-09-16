{ lib, ... }:
with lib;
{
  options = {
    shares = mkOption {
      type = types.nullOr types.ints.unsigned;
      description = ''
        CPU shares
        Relative CPU weight of the machine.
        Use `period` and `quota` to enforce hard limits
        to CPU usage.
      '';
      default = null;
    };

    period = mkOption {
      type = types.nullOr types.ints.unsigned;
      description = ''
        Enforcement period (us)
        Within each `period` the vCPU cannot consume more
        than `quota` worth of runtime.
        This is applied per vCPU.
      '';
      default = null;
    };

    quota = mkOption {
      type = types.nullOr types.ints.s32;
      description = ''
        vCPU quota (us)
        Within each `period` the vCPU cannot consume more
        than `quota` worth of runtime.
        A negative value means no limits will be applied.
        This is applied per vCPU.
      '';
      default = null;
    };
  };
}
