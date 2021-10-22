# Bird2
{ config, pkgs, lib, ... }:
with lib;
with builtins;
let
  cfg = config.turbo.networking.routing.bird2;
  genconfig = import ./genconfig.nix { inherit lib; };

  birdPackage = pkgs.bird2.overrideAttrs (old: {
    src = pkgs.fetchgit {
      url = "https://gitlab.nic.cz/labs/bird";
      rev = "82f19ba95e421f00a8e99a866a2b8d9bbdba6cdc";
      sha256 = "07mh41hsmkcpf6f6lnygzp6g59jma542pcqdkl54ysiqnjmi5zz1";
    };
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [
      pkgs.autoreconfHook
    ];
    patches = (old.patches or []) ++ [
      #./turbo-rpki-reload.patch
      ./zhaofeng-logging.patch
    ];
  });

  # == Sub-config files ==
  # node.conf
  nodeConf = pkgs.writeText "node.conf" (genconfig.nodeConf {
    inherit (cfg)
      routerId numericId
      iBgpAsn communityAsn
      ownPrefixes6 ownPrefixes4;

    region = config.turbo.networking.routing.region;
    config = config;
  });

  # static.conf
  staticConf = pkgs.writeText "static.conf" (concatStringsSep "\n" (lib.attrsets.mapAttrsToList (name: prot: genconfig.staticProtocol (prot // {
    inherit name config;
  })) cfg.staticProtocols));

  # ospf.conf
  ospfConf = pkgs.writeText "ospf.conf" (concatStringsSep "\n" (lib.attrsets.mapAttrsToList (name: prot: genconfig.ospfProtocol (prot // {
    inherit name;
  })) cfg.ospfProtocols));

  # bgp.conf
  bgpConf = pkgs.writeText "bgp.conf" (concatStringsSep "\n" (lib.attrsets.mapAttrsToList (name: peer: genconfig.bgpSession (peer // {
    inherit name config;
  })) cfg.bgpSessions));

  # == Computed ==
  # A list of interfaces on which we talk OSPF, for firewalling
  ospfAdvInterfaces =
    lib.lists.unique (lib.lists.flatten (lib.attrsets.mapAttrsToList (_: prot:
      (lib.attrsets.mapAttrsToList
        (name: area: attrNames
          (lib.attrsets.filterAttrs (iname: iopts: !iopts.stub) area.interfaces)
        )
        prot.areas
      )
    ) cfg.ospfProtocols))
  ;

  # == Options ==

  allChannels = [ "ipv4" "ipv6" ];

  staticProtocolType = types.submodule {
    options = {
      description = mkOption {
        description = "Description";
        default = null;
        type = types.nullOr types.str;
      };
      protocol = mkOption {
        description = "Protocol";
        type = types.enum allChannels;
      };
      table = mkOption {
        description = "Table";
        default = null;
        type = types.nullOr types.str;
      };
      routes = mkOption {
        description = "Routes";
        type = types.listOf types.str;
      };
      importFilter = mkOption {
        description = "Replace or add to the default import filter";
        type = types.either types.str filterType;
        default = {
          prepend = "";
          append = "";
        };
      };
      extraChannelConfigs = mkOption {
        description = "Extra channel configurations";
        type = types.lines;
        default = "";
      };
    };
  };

  ospfProtocolType = types.submodule {
    options = {
      description = mkOption {
        description = "Description";
        default = null;
        type = types.nullOr types.str;
      };
      version = mkOption {
        description = "Version";
        type = types.enum [ null "v2" "v3" ];
        default = null;
      };
      protocol = mkOption {
        description = "Protocol";
        type = types.enum allChannels;
      };
      # The OSPF areas are configured in an attrset 
      # to facilitate config merging. Area 0 must be
      # defined in the attribute `backbone`.
      areas = mkOption {
        description = "Areas";
        default = {
          backbone = {
            id = 0;
          };
        };
        type = types.attrsOf ospfAreaType;
      };
      extraConfigs = mkOption {
        description = "Extra configurations";
        type = types.lines;
        default = "";
      };
      extraChannelConfigs = mkOption {
        description = "Extra channel configurations";
        type = types.str;
        default = "";
      };
    };
  };

  ospfAreaType = types.submodule {
    options = {
      id = mkOption {
        description = ''
          Area ID

          Can be an integer or an IPv4 address, like routerId.
        '';
        example = "0.0.0.0";
        type = types.either types.str types.ints.unsigned;
      };
      stub = mkOption {
        description = "Stub area";
        default = "no";
        type = types.enum [ "no" "stub" "nssa" ];
      };
      interfaces = mkOption {
        description = "Interfaces";
        default = {};
        type = types.attrsOf ospfInterfaceType;
      };
      extraConfigs = mkOption {
        description = "Extra area configurations";
        type = types.str;
        default = "";
      };
    };
  };

  ospfInterfaceType = types.submodule {
    options = {
      interfaces = mkOption {
        description = ''
          Interface pattern(s)

          Leave empty to use the name of this section as the
          interface name.
        '';
        default = null;
        type = types.nullOr (types.listOf types.str);
      };
      stub = mkOption {
        description = "Stub interface";
        default = false;
        type = types.bool;
      };
      instance = mkOption {
        description = "Instance ID";
        default = null;
        type = types.nullOr types.ints.unsigned;
      };
      cost = mkOption {
        description = "Cost";
        default = null;
        example = 10;
        type = types.nullOr types.ints.unsigned;
      };
      authentication = mkOption {
        description = ''
          OSPF authentication type

          For null, the field will be entirely omitted
          if `password` is also null. Otherwise, 
          "authentication cryptographic;" will be
          emitted. Leave both this field and `password`
          null if you wish to configure authentication
          in `extraConfigs`.
        '';
        default = null;
        type = types.nullOr (types.enum [ "auto" "none" "cryptographic" ]);
      };
      password = mkOption {
        description = ''
          OSPF password

          If you want to specify other options like
          the algorithm, leave this field and `authentication`
          null and use extraConfigs :)
        '';
        default = null;
        type = types.nullOr types.str;
      };
      extraConfigs = mkOption {
        description = "Extra area configurations";
        type = types.str;
        default = "";
      };
    };
  };

  bgpSessionType = types.submodule {
    options = {
      description = mkOption {
        description = "Description";
        default = null;
        type = types.nullOr types.str;
      };
      localAS = mkOption {
        description = ''
          Local ASN

          Ignored for iBGP (will always use IBGP_ASN).
        '';
        type = types.ints.unsigned;
      };
      peerAS = mkOption {
        description = ''
          Peer ASN

          Ignored for iBGP (will always use IBGP_ASN).
        '';
        type = types.ints.unsigned;
      };
      realPeerAS = mkOption {
        description = ''
          Real peer ASN for purpose of filtering

          Ignored for iBGP.
        '';
        default = null;
        type = types.nullOr types.ints.unsigned;
      };
      neighbor = mkOption {
        description = "Peer endpoint";
        type = types.str;
      };
      iBgp = mkOption {
        description = ''
          This session is an iBGP session.

          If true, most other options will be ignored.
        '';
        default = false;
        type = types.bool;
      };
      rr = mkOption {
        description = ''
          We are a route reflector

          Also consider turning on addPaths. RR should at least do tx, and clients should rx.

          Ignored for eBGP.
        '';
        default = false;
        type = types.bool;
      };
      protocols = mkOption {
        description = ''
          Protocols to enable

          Ignored for iBGP. Both IPv4 and IPv6 are always enabled.
        '';
        default = allChannels;
        type = types.listOf (types.enum allChannels);
      };
      addPaths = mkOption {
        description = "Whether to enable the add-path/multipath extension";
        default = false;
        example = "rx";
        type = types.either types.bool (types.enum [ "off" "on" "rx" "tx" ]);
      };
      multihop = mkOption {
        description = ''
          Whether to use multihop or not

          Ignored for iBGP.
        '';
        default = false;
        example = 2;
        type = types.either types.bool types.ints.unsigned;
      };
      #gateway = mkOption {
      #  description = ''
      #    Method to compute the gateway for received routes

      #    Leave null to omit and use default behavior.
      #  '';
      #  default = null;
      #  example = "direct";
      #  type = types.nullOr (types.enum [ "direct" "recursive" ]);
      #};
      sourceAddress = mkOption {
        description = ''
          Source address to connect with

          Ignored for iBGP.
        '';
        default = null;
        type = types.nullOr types.str;
      };
      password = mkOption {
        description = "MD5 password to use";
        default = null;
        type = types.nullOr types.str;
      };
      prefixes = mkOption {
        # DOES NOT WORK YET
        description = "List of prefixes to accept. If empty, don't enable prefix list ACL.";
        default = [];
        example = [ "1.2.3.0/24" ];
        type = types.listOf types.str;
      };
      importFilter = mkOption {
        description = ''
          Replace or add to the default import filter

          Take care when using it for iBGP.
        '';
        type = types.either types.str filterType;
        default = {
          prepend = "";
          append = "";
        };
      };
      exportFilter = mkOption {
        description = ''
          Replace or add to the default export filter

          Take care when using it for iBGP.
        '';
        type = types.either types.str filterType;
        default = {
          prepend = "";
          append = "";
        };
      };
      relationship = mkOption {
        description = ''
          Relationship

          Ignored for iBGP.
        '';
        default = "peer";
        type = types.enum [
          "upstream"
          "downstream"
          "peer"
          "ixp"
          "collector"
          "bilateral"
        ];
      };
      localPref = mkOption {
        description = ''
          Default local-pref value to apply

          Ignored for iBGP. null means use default.
        '';
        default = null;
        type = types.nullOr types.ints.unsigned;
      };
      # In the past an eBGP session could permit multiple
      # networks in my config, a use case I no longer support.
      network = mkOption {
        description = ''
          Network

          Ignored for iBGP.
        '';
        default = "dfz";
        type = types.enum [
          "dfz"
          "dn42"
        ];
      };
      nextHopKeep = mkOption {
        description = ''
          Channels to activate `next hop keep` for

          Ignored for iBGP.
        '';
        default = [];
        type = types.listOf (types.enum allChannels);
      };
      ibgpExportExternal = mkOption {
        description = ''
          Export external routes to iBGP peer

          If disabled, we only export our own and downstreams'
          routes.

          Ignored for eBGP.
        '';
        default = true;
        type = types.bool;
      };
      extraChannelConfigs = mkOption {
        description = "Extra configurations for channel";
        type = types.attrsOf types.str;
        default = {};
      };
      extraConfigs = mkOption {
        description = "Extra configurations";
        type = types.str;
        default = "";
      };
    };
  };

  filterType = types.submodule {
    options = {
      prepend = mkOption {
        description = "Prepend the specified stanza to the filter";
        default = "";
        type = types.str;
      };
      append = mkOption {
        description = "Append the specified stanza to the filter";
        default = "";
        type = types.str;
      };
    };
  };
in
{
  options = {
    turbo.networking.routing.bird2 = {
      enable = mkOption {
        description = ''
          Run bird2 on this machine
        '';
        default = false;
        type = types.bool;
      };
      ibgp = mkOption {
        description = ''
          Set up iBGP sessions
        '';
        default = true;
        type = types.bool;
      };
      birdPackage = mkOption {
        description = ''
          The BIRD 2 package to use
        '';
        type = types.package;
        default = birdPackage;
      };
      baseConfig = mkOption {
        description = ''
          Base config package

          ''${baseConfig}/bird.conf will be included in the
          final configurations.
        '';
        type = types.package;
      };
      routerId = mkOption {
        type = types.str;
        example = "1.2.3.4";
        description = "The router ID";
      };
      numericId = mkOption {
        type = types.ints.unsigned;
        example = "1.2.3.4";
        default = 0;
        description = "The numeric ID for community tagging";
      };
      iBgpAsn = mkOption {
        type = types.ints.unsigned;
        example = 12345;
        description = ''
          The ASN used for iBGP sessions
        '';
      };
      communityAsn = mkOption {
        type = types.ints.unsigned;
        example = 12345;
        description = ''
          The ASN used for public control communities
        '';
      };
      ownPrefixes6 = mkOption {
        type = types.listOf types.str;
        example = [ "fd42:1234:5678::/48" ];
        description = ''
          IPv6 prefixes that we own

          We expect not to receive those prefixes over eBGP.
        '';
      };
      ownPrefixes4 = mkOption {
        type = types.listOf types.str;
        example = [ "1.2.3.0/24" ];
        description = ''
          IPv4 prefixes that we own

          We expect not to receive those prefixes over eBGP.
        '';
      };
      staticProtocols = mkOption {
        description = "Static protocol instances";
        type = types.attrsOf staticProtocolType;
        default = {};
      };
      ospfProtocols = mkOption {
        description = "OSPF protocol instances";
        type = types.attrsOf ospfProtocolType;
        default = {};
      };
      bgpSessions = mkOption {
        description = "BGP protocol instances";
        type = types.attrsOf bgpSessionType;
        default = {};
      };
      extraConfigs = mkOption {
        description = "Extra configurations";
        type = types.lines;
        default = "";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.birdPackage
    ];

    # bird.conf will change whenever bird2-config or nodeConf
    # is updated
    environment.etc."bird.conf".source = pkgs.runCommandLocal "validated-bird2.conf" {
      rawConfig = ''
        include "${nodeConf}";
        include "${cfg.baseConfig}/bird.conf";
        include "${staticConf}";
        include "${ospfConf}";
        include "${bgpConf}";

        # extraConfigs
        ${cfg.extraConfigs}
      '';
    } ''
      echo "$rawConfig" > $out
      ${cfg.birdPackage}/bin/bird -pc $out
    '';

    turbo.networking.firewall.filterInputRules = [
      {
        proto = "tcp"; dport = "bgp"; action = "ACCEPT";
      }
    ] ++ (map (i: {
      proto = 89; interface = i; action = "ACCEPT";
    }) ospfAdvInterfaces);

    systemd.services.bird2 = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "BIRD routing daemon";
      serviceConfig = {
        Type = "forking";
        ExecStart = "${cfg.birdPackage}/bin/bird -c /etc/bird.conf -s /run/bird2/bird.ctl";
        ExecReload = "${cfg.birdPackage}/bin/birdc configure";
        ExecStop = "${cfg.birdPackage}/bin/birdc down";
        Restart = "always";
        RuntimeDirectory = "bird2";

        # https://gitlab.nic.cz/labs/bird/-/blob/9f24fef5e91fb4df301242ede91ee7ac1b46b8a8/sysdep/linux/syspriv.h#L57-61
        AmbientCapabilities = [
          "CAP_NET_ADMIN"
          "CAP_NET_BIND_SERVICE"
          "CAP_NET_BROADCAST"
          "CAP_NET_RAW"
        ];
      };
    };

    # Socket proxy
    #
    # This allows bird itself to be run as non-root and create
    # the socket in its RuntimePath (/run/bird2/bird.ctl).
    systemd.sockets.bird2-socket = {
      wantedBy = ["sockets.target"];
      socketConfig = {
        ListenStream = "/run/bird.ctl";
      };
    };

    systemd.services.bird2-socket = {
      requires = [ "bird2.service" ];
      after = [ "bird2.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd /run/bird2/bird.ctl";
      };
    };

    # Ugly hack :(
    #
    # Taken from `nixpkgs/nixos/modules/services/web-servers/nginx/default.nix`
    #
    # If there is a cleaner way to reload a service in
    # response to a change in some derivation or config value,
    # please let me know!
    systemd.services.bird2-config-reload = {
      wants = [ "bird2.service" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [
        config.environment.etc."bird.conf".source
        #/etc/bird.conf
      ];
      serviceConfig = {
        Type = "oneshot";
        TimeoutSec = 60;
        RemainAfterExit = true;
      };
      script = ''
        if /run/current-system/systemd/bin/systemctl -q is-active bird2.service ; then
          /run/current-system/systemd/bin/systemctl reload bird2.service
        fi
      '';
    };

    # Periodically reload eBGP imports for RPKI changes
    systemd.timers.bird2-reload-ebgp = {
      partOf = [ "bird2.service" ];
      bindsTo = [ "bird2.service" ];
      wantedBy = [ "timer.target" ];
      timerConfig = {
        OnActiveSec = "1h";
        OnUnitActiveSec = "1d";
      };
    };
    systemd.services.bird2-reload-ebgp = let
      ebgpSessions = attrNames (lib.filterAttrs (k: v: !v.iBgp) cfg.bgpSessions);
      reload = let
        commands = map (n: "${cfg.birdPackage}/bin/birdc reload in ${n}") ebgpSessions;
      in concatStringsSep "\n" commands;
    in {
      script = ''
        echo "Reloading eBGP sessions..."
        ${reload}
      '';
      serviceConfig = {
        Type = "oneshot";
      };
    };
  };
}
