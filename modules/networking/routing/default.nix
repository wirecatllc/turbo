# Routing suite
{ config, pkgs, lib, ... }:
with builtins;

let
  cfg = config.turbo.networking.routing;
  mkIpOption = description: lib.mkOption {
    type = types.nullOr types.str;
    description = description;
    default = null;
  };
  genNetworkingIp = ips: prefixLength:
    map (el: {
      address = el;
      prefixLength = prefixLength;
    }) (filter (el: el != null) ips);

  types = lib.types;
in
{
  imports = [
    ./bird2
    ./rtr
    ./jool
    ./dhcp
  ];

  options = {
    turbo.networking.routing = {
      enable = lib.mkOption {
        description = ''
          Whether to use this machine as a router.
        '';
        type = types.bool;
        default = false;
      };
      core = lib.mkOption {
        description = ''
          Whether this router is a core router.
        '';
        type = types.bool;
        default = false;
      };
      stub = lib.mkOption {
        description = ''
          Whether this router is a stub router.
        '';
        type = types.bool;
        default = false;
      };
      ngtun = lib.mkOption {
        description = ''
          Enable ngtun configurations.
        '';
        type = types.bool;
        default = true;
      };
      name = lib.mkOption {
        description = ''
          Name of the router.
        '';
        type = types.nullOr types.str;
        default = null;
      };
      asns = lib.mkOption {
        description = ''
          ASNs of the router.
        '';
        type = types.submodule {
          options = {
            dfz = lib.mkOption {
              description = "Internet ASN";
              type = types.ints.unsigned;
            };
            dn42 = lib.mkOption {
              description = "DN42 ASN";
              type = types.ints.unsigned;
            };
          };
        };
      };
      addresses = lib.mkOption {
        description = ''
          Addresses of the router.
        '';
        type = types.submodule {
          options = {
            v4 = mkIpOption "IPv4 Address";
            v6 = mkIpOption "IPv6 Address";
            dn4 = mkIpOption "DN42 IPv4 Address";
            dn6 = mkIpOption "DN42 IPv6 Address";
          };
        };
        default = {
          v4 = null;
          v6 = null;
          dn4 = null;
          dn6 = null;
        };
      };
      region = lib.mkOption {
        description = ''
          Physical region of the router.
        '';
        type = types.nullOr (types.enum [
          "eu"
          "na_e"
          "na_c"
          "na_w"
          "ap_e"
          "ap_o"
        ]);
        default = null;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.useNetworkd = true;
    systemd.network.enable = true;

    networking.interfaces.lo.ipv4.addresses = genNetworkingIp [
      cfg.addresses.v4
      cfg.addresses.dn4
    ] 32;

    networking.interfaces.lo.ipv6.addresses = genNetworkingIp [
      cfg.addresses.v6
      cfg.addresses.dn6

      # Bird doesn't want distribute loopback addresses on OSPFv3
      # without it having a link-local address... An alternative
      # solution is to create a `dummy` interface and set the IP
      # there.
      "fe80::1"
    ] 128;

    environment.etc."systemd/networkd.conf.d/ignore-foreign-routes.conf".text = ''
      [Network]
      ManageForeignRoutes=false
    '';

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = lib.mkOverride 99 1;
      "net.ipv6.conf.all.forwarding" = lib.mkOverride 99 1;
      "net.ipv6.route.max_size" = 262144;
    } // lib.optionalAttrs cfg.bird2.enable {
      "net.ipv4.conf.all.rp_filter" = 0;
      "net.ipv4.conf.default.rp_filter" = 0;
    };

    networking.firewall.enable = false;
    turbo.networking.firewall.enable = true;

    environment.systemPackages = with pkgs; [
      # Some network utilities
      tcpdump iperf3 dropwatch mtr traceroute ldns whois ipset ethtool
    ];

    # Also set up ngtun :)
    turbo.networking.ngtun = lib.mkIf cfg.ngtun {
      node = {
        groups = [ "routers" ] 
          ++ lib.optional (cfg.region != null) cfg.region
          ++ lib.optional (cfg.core) "routers-core";
      };
    };

    deployment.tags = [ "routers" ]
      ++ lib.optional (cfg.core) "routers-core";
  };
}
