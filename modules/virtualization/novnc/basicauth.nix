# Argo Tunnel Backend

{ config, pkgs, lib, ... }:

with builtins;
let
  cfg = config.turbo.virtualization.services.novnc;
  basicauthMachines = lib.filterAttrs (k: v: v.backend == "basicauth") cfg.machines;
in
{
  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts = lib.mapAttrs'
      (machineName: machine:
        let
        in
        {
          name = "vnc-${machineName}.${cfg.baseDomain}";
          value = {
            listen = [
              {
                addr = "[::1]";
                port = 50001;
              }
            ];

            extraConfig = ''
              allow ::1;
              deny all;
            '';

            root = "${cfg.novncPackage}/share/webapps/novnc/";
            basicAuth.${machine.username} = machine.password;
            locations."/websockify" = {
              proxyWebsockets = true;
              proxyPass = "http://[::1]:14000";
              extraConfig = ''
                proxy_read_timeout 61s;
                proxy_buffering off;
                proxy_set_header Host            $host;
              '';
            };
            locations."/" = {
              index = "vnc.html";
            };
          };
        })
      basicauthMachines;
  };
}
