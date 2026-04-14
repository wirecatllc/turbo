{ lib, pkgs, config, ... }:
with builtins;
let
  cfg = config.turbo.networking.isp-split-tunnel;
  types = lib.types;
in
{
  options = {
    turbo.networking.isp-split-tunnel = {
      enable = lib.mkEnableOption "ISP split-tunneling setup";
      interface = lib.mkOption {
        description = "Name of the provider interface";
        type = types.str;
      };
      v4 = lib.mkOption {
        description = "Provider IPv4 address";
        type = types.nullOr types.str;
        default = null;
      };
      v6 = lib.mkOption {
        description = "Provider IPv6 address";
        type = types.nullOr types.str;
        default = null;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    networking.nftables.tables."wirecat-connmark4" = lib.mkIf (cfg.v4 != null) {
      family = "ip";
      content = ''
        chain output {
          type route hook output priority mangle;
          ct mark != 0 meta mark set ct mark accept
          ip saddr ${cfg.v4} meta mark set 0x1
          ct mark set meta mark
        }
        chain input-mark {
          type filter hook input priority mangle;
          ct mark != 0 meta mark set ct mark accept
          iifname "${cfg.interface}" ip daddr ${cfg.v4} meta mark set 0x1
          ct mark set meta mark
        }
      '';
    };

    networking.nftables.tables."wirecat-connmark6" = lib.mkIf (cfg.v6 != null) {
      family = "ip6";
      content = ''
        chain output {
          type route hook output priority mangle;
          ct mark != 0 meta mark set ct mark accept
          ip6 saddr ${cfg.v6} meta mark set 0x1
          ct mark set meta mark
        }
        chain input-mark {
          type filter hook input priority mangle;
          ct mark != 0 meta mark set ct mark accept
          iifname "${cfg.interface}" ip6 daddr ${cfg.v6} meta mark set 0x1
          ct mark set meta mark
        }
      '';
    };

    systemd.network.networks."${cfg.interface}" = {
      name = cfg.interface;
      routingPolicyRules = [
        {
          routingPolicyRuleConfig = {
            Family = "both";
            FirewallMark = 1;
            Table = 1;
          };
        }
      ];
    };
  };
}
