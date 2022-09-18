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
  config = lib.mkIf cfg.enable (
    let
      genTable = address: {
        # FIXME: This is bad when we want to add other fwmarks...
        mangle.chains.output.prepends = lib.optional (address != null) ''
          CONNMARK restore-mark;
          mod mark mark ! 0 ACCEPT;
          saddr ${address} MARK set-mark 0x1;
          CONNMARK save-mark;
        '';
        mangle.chains.input.prepends = lib.optional (address != null) ''
          CONNMARK restore-mark;
          mod mark mark ! 0 ACCEPT;
          interface ${cfg.interface} daddr ${address} MARK set-mark 0x1;
          CONNMARK save-mark;
        '';
      };
    in
    {
      # IPv4
      turbo.networking.firewall.ip = genTable cfg.v4;
      turbo.networking.firewall.ip6 = genTable cfg.v6;

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
    }
  );
}