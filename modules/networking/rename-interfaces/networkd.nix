{ lib, config, ... }:

with builtins;
let
  cfg = config.zhaofeng.networking.rename-interfaces;
in {
  config = lib.mkIf (cfg.enable && cfg.method == "networkd") {
    networking.useNetworkd = true;
    systemd.network.links = lib.mapAttrs' (name: mac: {
      name = "10-${name}";
      value = {
        matchConfig = {
          MACAddress = mac;
          Type = "!vlan bridge";
        };
        linkConfig = {
          Name = name;
        };
      };
    }) cfg.interfaces;
  };
}
