{ lib, ... }:

with lib;
{
  options = {
    name = mkOption {
      type = types.str;
      description = ''
        Assigned device name
      '';
    };

    mac = mkOption {
      type = types.str;
      description = ''
        Device MAC Address
      '';
      example = "66:cd:f9:97:98:04";
    };

    address = mkOption {
      default = null;
      type = with types; nullOr str;
      description = ''
        Assigned IP address
      '';
    };

    router = mkOption {
      default = null;
      type = with types; nullOr str;
      description = '' 
        DHCP router assignment
      '';
    };

    dns = mkOption {
      default = null;
      type = with types; nullOr str;
      description = ''
        DHCP DNS Assignment
      '';
    };

    extraOptions = mkOption {
      default = null;
      type = with types; nullOr str;
      description = ''
        Extra configs to append to host config
      '';
    };
  };
}
