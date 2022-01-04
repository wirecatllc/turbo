# Jool

{ config, pkgs, lib, ... }:
with lib;
with builtins;
let
  cfg = config.turbo.networking.routing.jool;
  instanceOptions = {
    options = {
      config = mkOption {
        type = types.str;
        description = ''
          The JSON configuration file

          See https://jool.mx/en/config-atomic.html for examples.
        '';
      };
    };
  };
  joolServices = let
    configFile = name: instance: pkgs.writeText "jool-${name}.json" instance.config;
    services = attrsets.mapAttrsToList (name: instance: {
      name = "jool-${name}";
      value = {
        # https://raw.githubusercontent.com/ydahhrk/packaging/master/Jool/debian/jool-tools.jool.service
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        description = "Jool NAT64 ${name}";
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = "${pkgs.kmod}/bin/modprobe jool";
          ExecStart = "${pkgs.jool-cli}/bin/jool file handle ${configFile name instance}";
          ExecStop = "${pkgs.jool-cli}/bin/jool -f ${configFile name instance} instance remove";
          RemainAfterExit = "yes";

          CapabilityBoundingSet = [ "CAP_SYS_MODULE" "CAP_NET_ADMIN" ];
          NoNewPrivileges = "yes";
          ProtectSystem = "strict";
          ProtectHome = "yes";
          InaccessiblePaths = [ "/tmp" "/dev" ];
          ProtectKernelTunables = "yes";
          ProtectKernelModules = "no";
          ProtectControlGroups = "yes";
          RestrictAddressFamilies = "AF_NETLINK";
          RestrictNamespaces = "yes";
          LockPersonality = "yes";
          MemoryDenyWriteExecute = "yes";
          RestrictRealtime = "yes";
          SystemCallArchitectures = "native";
        };
      };
    }) cfg.instances;
  in listToAttrs services;
in {
  options = {
    turbo.networking.routing.jool = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Run Jool, a NAT64 gateway, on this machine
        '';
      };
      instances = mkOption {
        type = types.attrsOf (types.submodule instanceOptions);
        default = {};
        description = ''
          A set of NAT64 instances to run

          Configure SIIT instances in siitInstances.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jool-cli
    ];

    boot.extraModulePackages = with config.boot.kernelPackages; [
      jool
    ];

    systemd.services = joolServices;
  };
}
