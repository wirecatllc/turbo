{ lib, pkgs, config, ... }:
with builtins;
let
  cfg = config.turbo.networking.ngtun;
  cfgPath = [ "turbo" "services" "ngtun" ];

  # deprecated
  renderNetdev = name: tunnel: {
    netdevConfig = {
      Kind = "wireguard";
      Name = name;
    };
    extraConfig = ''
      [WireGuard]
      PrivateKey=${cfg.node.privateKey}
      ListenPort=${toString tunnel.listenPort}
      FirewallMark=${toString cfg.global.fwMark}

      [WireGuardPeer]
      PublicKey=${tunnel.publicKey}
      AllowedIPs=0.0.0.0/0,::/0
    '' + lib.optionalString (tunnel.endpoint != null) ''
      Endpoint=${tunnel.endpoint}
    '' + lib.optionalString tunnel.persistentKeepalive ''
      PersistentKeepalive=25
    '';
  };

  renderTunnel = name: tunnel: {
    privateKey = cfg.node.privateKey;
    listenPort = tunnel.listenPort;
    fwMark = cfg.global.fwMark;
    peers = [
      (
        {
          publicKey = tunnel.publicKey;
          allowedIPs = [ "0.0.0.0/0" "::/0" ];
        } // lib.optionalAttrs (tunnel.endpoint != null) {
          endpoint = tunnel.endpoint;
        } // lib.optionalAttrs (tunnel.persistentKeepalive) {
          persistentKeepalive = 25;
        }
      )
    ];
  };

  renderNetwork = name: tunnel: let
    llnum = toString tunnel.linkLocalId;
  in
    assert (lib.assertMsg config.networking.useNetworkd "systemd-networkd must be enabled for ngtun to work");
  {
    inherit name;
    networkConfig = {
      LinkLocalAddressing = "no";
    };
    addresses = [
      {
        addressConfig = {
          Address = "172.30.0.${toString (tunnel.myId + 1)}/32";
          Peer = "172.30.0.${toString (tunnel.peerId + 1)}/32";
        };
      }
      {
        addressConfig = {
          Address = "fe80::${llnum}/64";
          Scope = "link";
        };
      }
    ];
  };

  renderFirewall = name: tunnel: {
    proto = "udp";
    dport = tunnel.listenPort;
    action = "ACCEPT";
  };
in {
  config = lib.mkIf cfg.enable {
    #systemd.network.netdevs = lib.mapAttrs renderNetdev cfg.generatedTunnels;
    systemd.network.networks = lib.mapAttrs renderNetwork cfg.generatedTunnels;

    turbo.networking.wireguard.tunnels = lib.mapAttrs renderTunnel cfg.generatedTunnels;

    turbo.networking.firewall.filterInputRules = lib.mapAttrsToList renderFirewall cfg.generatedTunnels;
  };
}
