# wg-quick renderer
#
# Well, it does kernel as well, but we prefer to use
# networkd instead and leave wg-quick to handle only
# the userspace wg implementation.

{ pkgs, lib, config, ... }:
with builtins;
let
  cfg = config.turbo.networking.wireguard;

  renderPeer = peer: {
    inherit (peer) allowedIPs endpoint publicKey;
    persistentKeepalive = if peer.persistentKeepalive == 0 then null else peer.persistentKeepalive;
  };

  renderInterface = name: tunnel:
    let
      peers = map renderPeer tunnel.peers;
    in
    {
      inherit (tunnel) privateKey listenPort;
      table = "off";

      postUp = ''
        ${pkgs.wireguard-tools}/bin/wg set ${name} fwmark ${toString tunnel.fwMark}
      '';
    };

  renderUnit = name: tunnel: {
    name = "wg-quick-${name}";
    value = {
      environment.WG_QUICK_USERSPACE_IMPLEMENTATION = "${pkgs.boringtun}/bin/boringtun";
    };
  };

in
{
  config = lib.mkIf (cfg.backend == "userspace") {
    networking.wg-quick.interfaces = lib.mapAttrs renderInterface cfg.tunnels;

    systemd.services = lib.mapAttrs' renderUnit cfg.tunnels;
  };
}
