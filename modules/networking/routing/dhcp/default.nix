{ config, lib, ... }:
with lib;
let
  cfg = config.turbo.networking.routing.dhcp;
  subnetOptions = types.submodule (import ./subnet-options.nix {
    inherit lib;
  });

  utils = import ./utils.nix {
    inherit lib;
  };

  configText = utils.buildConfig cfg;
in
{
  options = {
    turbo.networking.routing.dhcp = {
      enable = mkOption {
        default = false;
        type = with types; bool;
        description = ''
          Whether to enable an dhcp modules
        '';
      };

      subnets = mkOption {
        default = [ ];
        type = with types; listOf subnetOptions;
        description = ''
          A list of subnets configs
        '';
        example = ''
          {
            interface = "main";
            ip = "192.168.1.0";
            netmask = "255.255.255.0";
            rangeBegin = "192.168.1.10";
            rangeEnd = "192.168.1.200";
            dns = "1.1.1.1, 1.0.0.1";
            router = "192.168.1.1";

            hosts = [
              ## Devices
              { name = "SomeDevice";
                mac = "66:cd:f9:97:98:04";
                address =  "192.168.1.5";
              }
            ];
          }
        '';
      };

      enableIpxe = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether to enable IPXE
        '';
      };

      interfaces = mkOption {
        default = [ ];
        type = with types; listOf str;
        description = ''
          A list of interface names
        '';
        example = ''
          [ "iot" "guest" "management" "ap" "sensitive" ];
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    services.dhcpd4 = {
      enable = true;
      interfaces = cfg.interfaces;
      extraConfig = configText;
    };
  };
}
