# Modified version of Indexyz's novnc module.
#
# This module supports multiple backends. In the Cloudflare Access ("cfaccess")
# mode, simple NGINX virtualHosts are configured to accept proxied requests
# from Cloudflare, authenticated with Cloudflare's Origin Pull certificates.
# Authentication is configured through Cloudflare Access.
#
# In the Basic Auth ("basicauth") mode, HTTP basic auth is used to provide
# authentication.

{ config, pkgs, lib, ... }:

with builtins;
let
  cfg = config.turbo.virtualization.services.novnc;

  types = lib.types;

  machineType = types.submodule {
    options = {
      backend = lib.mkOption {
        description = ''
          Backend
        '';
        type = types.enum [ "basicauth" ];
        default = "basicauth";
      };
      username = lib.mkOption {
        description = ''
          Basic Auth Username

          Only used when mode is set to "basicauth".
        '';
        type = types.str;
      };
      password = lib.mkOption {
        description = ''
          Basic Auth Password

          Only used when mode is set to "basicauth".
        '';
        type = types.str;
      };
    };
  };

  tokenFile =
    let
      tokens = lib.mapAttrsToList
        (machineName: machine:
          let
            vncBase = "/run/hypervisor/vnc";
            vncSocket = "${vncBase}/${machineName}";
          in
          "vnc-${machineName}.${cfg.baseDomain}: unix_socket:${vncSocket}"
        )
        cfg.machines;
    in
    pkgs.writeText "novnc-tokens.txt" (concatStringsSep "\n" tokens);
in
{
  imports = [
    ./basicauth.nix
  ];
  options = {
    turbo.virtualization.services.novnc = {
      enable = lib.mkOption {
        description = ''
          Enable noVNC page
        '';
        type = types.bool;
        default = false;
      };
      internalPort = lib.mkOption {
        description = ''
          Port to listen for noVNC WebSocket
        '';
        type = types.ints.unsigned;
      };
      baseDomain = lib.mkOption {
        description = ''
          Basic domain for noVNC

          For example, with baseDomain set to "gaia.indexyz.me", VNC
          console for a machine will be accessible via
          [machine name].gaia.indexyz.me.
        '';
        type = types.str;
        example = "gaia.indexyz.me";
      };
      novncPackage = lib.mkOption {
        description = ''
          noVNC package to use
        '';
        type = types.package;
        default = pkgs.novnc;
      };
      websockifyPackage = lib.mkOption {
        description = ''
          Websockify package to use
        '';
        type = types.package;
        default = pkgs.python3Packages.websockify;
      };

      machines = lib.mkOption {
        type = types.attrsOf machineType;
        default = { };
        description = ''
          Machines
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."websockify-novnc" = {
      description = "Websockify for novnc";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.websockifyPackage}/bin/websockify --host-token --token-plugin ReadOnlyTokenFile --token-source ${tokenFile} [::1]:${toString cfg.internalPort}";
        Restart = "always";
      };
    };
  };
}
