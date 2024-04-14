# Argo Tunnel / cloudflared

{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.turbo.networking.argo-tunnel;
  supercfg = config;
  # https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/configuration-file/ingress
  tunnelOptions = {
    options = {
      ingress = mkOption {
        type = types.listOf (types.submodule ingressOptions);
        default = [ ];
        description = ''
          Ingress to create
        '';
      };

      credentialsFile = mkOption {
        type = types.path;
        default = null;
        description = ''
          Credential JSON file for tunnel
        '';
      };
      tunnelId = mkOption {
        type = types.str;
        default = null;
        description = ''
          Tunnel UUID
        '';
      };
    };
  };

  ingressOptions = {
    options = {
      hostname = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = ''
          gitlab.widgetcorp.tech
        '';
        description = ''
          match rules for host
        '';
      };
      service = mkOption {
        type = types.str;
        example = ''
          http://localhost:80
        '';
        description = ''
          target URL
          https://developers.cloudflare.com/cloudflare-one/applications/non-http
        '';
      };
    };
  };

  tunnelConfig = name: tunnel: pkgs.writeText "tunnel.json" (builtins.toJSON {
    tunnel = tunnel.tunnelId;
    credentials-file = tunnel.credentialsFile;
    no-autoupdate = true;
    ingress = tunnel.ingress;
  });

  tunnelServices =
    let
      tunnels = attrsets.mapAttrsToList
        (name: tunnel: {
          name = "cloudflared-tunnel-${name}";
          value = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            description = "Argo Tunnel ${name}";
            serviceConfig = {
              Type = "simple";
              ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config=${tunnelConfig name tunnel} run";
              TimeoutStopSec = 10;
              Restart = "always";
              StartLimitIntervalSec = 0;
            };
          };
        })
        cfg.tunnels;
    in
    builtins.listToAttrs tunnels;
in
{
  options = {
    turbo.networking.argo-tunnel = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable Argo Tunnel Endpoint
        '';
      };

      tunnels = mkOption {
        type = types.attrsOf (types.submodule tunnelOptions);
        default = { };
        description = ''
          Tunnels to create

          to generate token: cloudflared tunnel create my-secret-app
        '';
        example = ''
          my-secret-app = {
            credentialsFile = "/persist/secrets/cf-vnc-tunnel.json";
            tunnelId = "abcdefgh-abcd-abcd-abcd-abcdabcdabcd";
            ingress = [
              {
                service = "http://[::1]";
              }
            ];
          };
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cloudflared
    ];

    boot.kernel.sysctl = {
      "net.core.rmem_max" = 2500000;
    };

    systemd.services = tunnelServices;
  };
}
