# systemd-networkd renderer

{ pkgs, lib, config, ... }:
with builtins;
let
  cfg = config.turbo.networking.wireguard;

  renderPeer = peer: ''
    [WireGuardPeer]
    PublicKey=${peer.publicKey}
    AllowedIPs=${concatStringsSep "," peer.allowedIPs}
  '' + lib.optionalString (peer.endpoint != null) ''
    Endpoint=${peer.endpoint}
  '' + lib.optionalString (peer.persistentKeepalive != 0) ''
    PersistentKeepalive=${toString peer.persistentKeepalive}
  '';

  renderNetdev = name: tunnel:
    let
      peers = map renderPeer tunnel.peers;
    in
    {
      netdevConfig = {
        Kind = "wireguard";
        Name = name;
      };
      extraConfig = ''
        [WireGuard]
        PrivateKey=${tunnel.privateKey}
        ListenPort=${toString tunnel.listenPort}
        FirewallMark=${toString tunnel.fwMark}

        ${concatStringsSep "\n" peers}
      '';
    };
in
{
  config = lib.mkIf (cfg.backend == "kernel") {
    systemd.network.netdevs = lib.mapAttrs renderNetdev cfg.tunnels;
  };
}
