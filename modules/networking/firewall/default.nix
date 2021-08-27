# Firewall

{ config, pkgs, lib, ... } @ context:
with lib;
with builtins;
let
  cfg = config.turbo.networking.firewall;
  genconfig = import ./genconfig.nix context;

  mkChain = description: mkOption {
    inherit description;
    default = {};
    type = chainType;
  };

  mkTable = name: mkOption {
    description = "${name} table";
    default = {};
    type = types.submodule {
      options = {
        chains = mkOption {
          description = "Chains";
          type = types.attrsOf chainType;
          default = {};
        };
        prepends = mkOption {
          description = "Extra configs to be prepended";
          default = [];
          type = types.listOf types.str;
        };
        appends = mkOption {
          description = "Extra configs to be appended";
          default = [];
          type = types.listOf types.str;
        };
      };
    };
  };

  mkTableAttr = name: {
    name = name;
    value = mkTable name;
  };

  # tables <- list of mkTableAttr
  mkDomain = name: tables: let
  in mkOption {
    description = "${name}";
    default = {};
    type = types.submodule {
      options = tables;
    };
  };

  ruleType = types.submodule {
    options = let
      mkFilter = description: mkOption {
        inherit description;
        default = null;
        type = types.nullOr (types.either
        (types.either types.str types.ints.unsigned)
        (types.listOf (types.either types.str types.ints.unsigned)));
      };
      mkStr = description: mkOption {
        inherit description;
        default = null;
        type = types.nullOr types.str;
      };
    in {
      module = mkStr "Load module";
      description = mkStr "Description";

      interface = mkFilter "Incoming interface";
      outerface = mkFilter "Outgoing interface";
      proto = mkFilter "Protocol";
      sport = mkFilter "Source port";
      dport = mkFilter "Destination port";
      saddr = mkFilter "Source address";
      daddr = mkFilter "Destination address";
      mark = mkFilter "Match mark";

      extraFilters = mkOption {
        description = "Extra filters";
        default = "";
        type = types.str;
      };

      action = mkOption {
        description = "Action";
        default = "ACCEPT";
        type = types.str;
        #type = types.enum [ "ACCEPT" "REJECT" "DROP" "DNAT" "SNAT" "MASQUERADE" "MARK" "jump" ];
      };
      args = mkOption {
        description = "Extra arguments following the action";
        default = null;
        type = types.nullOr types.str;
      };
    };
  };

  chainType = types.submodule {
    options = {
      prepends = mkOption {
        description = "Rules to prepend";
        default = [];
        type = types.listOf types.str;
      };
      appends = mkOption {
        description = "Rules to append";
        default = [];
        type = types.listOf types.str;
      };
      rules = mkOption {
        description = "Rules";
        default = [];
        type = types.listOf ruleType;
      };
      policy = mkOption {
        description = "Policy";
        default = null;
        type = types.nullOr types.str;
      };
    };
  };

  # FIXME: Remove fixed chains
  commonDomTables = let
    filter = mkTableAttr "filter";
    nat = mkTableAttr "nat";
    mangle = mkTableAttr "mangle";
  in listToAttrs [ filter nat mangle ];
in
{
  options = {
    turbo.networking.firewall = {
      enable = mkOption {
        description = "Enable the ferm firewall";
        default = false;
        type = types.bool;
      };
      # dom -> table -> chain
      ip = mkDomain "ip" commonDomTables;
      ip6 = mkDomain "ip6" commonDomTables;

      # Simple options
      filterInputRules = mkOption {
        description = "Common INPUT rules for both v4 and v6";
        default = [];
        type = types.listOf ruleType;
      };

      macros = mkOption {
        description = ''
          Macros

          If you define a macro named abc, then @abc@ in all
          rules will be replaced with its content.
        '';
        default = {};
        type = types.attrsOf types.str;
      };

      extraConfigs = mkOption {
        description = "Extra configs to be added";
        default = [];
        type = types.listOf types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.enable = false;
    services.ferm.enable = true;

    # Simple TCP rules
    turbo.networking.firewall.ip.filter.chains.input.rules = cfg.filterInputRules;
    turbo.networking.firewall.ip6.filter.chains.input.rules = cfg.filterInputRules;

    environment.systemPackages = with pkgs; [
      iptables
    ];

    services.ferm.config = ''
      ${genconfig.domain "ip" cfg.ip}
      ${genconfig.domain "ip6" cfg.ip6}
      ${concatStringsSep "\n" cfg.extraConfigs}
    '';
  };
}
