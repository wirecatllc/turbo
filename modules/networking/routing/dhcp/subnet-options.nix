{ lib, ... }:

with lib;
let
  hostOptions = types.submodule (import ./host-options.nix {
    inherit lib;
  });
in
{
  options = {
    ip = mkOption {
      type = types.str;
      description = ''
        IP CIDR
      '';
      example = "192.168.1.0";
    };

    netmask = mkOption {
      type = types.str;
      default = "255.255.255.0";
      description = ''
        Netmask Range
      '';
    };

    rangeBegin = mkOption {
      type = types.str;
      description = ''
        IP pool start IP
      '';
      example = "192.168.1.5";
    };

    rangeEnd = mkOption {
      type = types.str;
      description = ''
        IP pool end IP
      '';
      example = "192.168.1.150";
    };

    dns = mkOption {
      default = null;
      type = with types; nullOr str;
      description = ''
        DHCP assigned DNS
      '';
      example = ''
        1.1.1.1, 1.0.0.1
      '';
    };

    router = mkOption {
      default = null;
      type = with types; nullOr str;
      description = ''
        DHCP router IP
      '';
      example = "192.168.1.1";
    };

    ipxeFile = mkOption {
      default = null;
      type = with types; nullOr str;
      description = ''
        IPXE file
      '';
      example = ''
        https://boot.netboot.xyz
      '';
    };

    tftpServer = mkOption {
      default = null;
      type = with types; nullOr str;
      description = ''
        tftp server IP
      '';
      example = "172.16.0.1";
    };

    interface = mkOption {
      default = null;
      type = with types; nullOr str;
      description = ''
        list of interface name to apply
      '';
    };

    hosts = mkOption {
      default = [ ];
      type = types.listOf hostOptions;
      description = ''
        List of host definition in this subnet
      '';
    };

    extraConfig = mkOption {
      default = "";
      type = types.str;
      description = ''
        Extra config to append
      '';
    };
  };
}
