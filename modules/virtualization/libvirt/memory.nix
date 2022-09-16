{ lib, ... }:
with lib;
let
in
{
  options = {
    unit = mkOption {
      type = types.nullOr (types.enum [
        "b"
        "bytes"
        "k"
        "KiB"
        "MB"
        "M"
        "MiB"
        "GB"
        "G"
        "GiB"
        "TB"
        "T"
        "TiB"
      ]);
      description = ''
        defaults to "KiB" (kibibytes, 210 or blocks of 1024 bytes).
        Valid units are "b" or "bytes" for bytes, 
        "KB" for kilobytes (103 or 1,000 bytes), 
        "k" or "KiB" for kibibytes (1024 bytes), 
        "MB" for megabytes (106 or 1,000,000 bytes), 
        "M" or "MiB" for mebibytes (220 or 1,048,576 bytes),
        "GB" for gigabytes (109 or 1,000,000,000 bytes), 
        "G" or "GiB" for gibibytes (230 or 1,073,741,824 bytes), 
        "TB" for terabytes (1012 or 1,000,000,000,000 bytes), 
        or "T" or "TiB" for tebibytes (240 or 1,099,511,627,776 bytes). 
        However, the value will be rounded up to the nearest kibibyte by libvirt, 
        and may be further rounded to the granularity supported by the hypervisor. 
      '';
      default = "KiB";
    };

    size = mkOption {
      type = types.ints.unsigned;
      description = ''
        The maximum allocation of memory for the guest at boot time. The memory allocation includes possible additional memory devices specified at start or hotplugged later.
      '';
      example = 524288;
    };
  };
}
