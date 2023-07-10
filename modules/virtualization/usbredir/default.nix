{ config, pkgs, lib, ... }:
with lib;
let 
    cfg = config.turbo.virtualization.usbredir; 
    usbredir = {
        options = {
            device = mkOption {
                type = types.str;
                example = "3553:b001";
                description = ''
                    USB Device to redir. If device does not exist, usbredir will fail
                '';
            };
            address = mkOption {
                type = types.str;
                example = "localhost:4000";
                description = ''
                    Which address to bind to/connect to
                '';
            };
            mode = mkOption {
                type = types.enum ["client" "server"];
                description = ''
                    Which mode to use
                '';
            };
        };
    };
in
{
    options = {
        turbo.virtualization.usbredir = mkOption {
            type = types.attrsOf (types.submodule usbredir);
            default = {};
        };
    };

    config = {
        systemd.services = builtins.listToAttrs (mapAttrsToList (
            name: val:
            let 
            in {
                name = "usbredir-${name}";
                value = {
                    restartIfChanged = true;
                    wantedBy = [ "multi-user.target" ];
                    unitConfig = {
                        StartLimitIntervalSec = 0;
                    };
                    serviceConfig = {
                        ExecStart = "${pkgs.usbredir}/bin/usbredirect --device ${val.device} ${if val.mode == "client" then "--to" else "--as"} ${val.address}";
                        Restart = "always";
                        RestartSec = 1;
                    };
                };
            }
        ) cfg);
    };
}