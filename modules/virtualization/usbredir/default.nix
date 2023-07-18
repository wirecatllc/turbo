{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.turbo.virtualization.usbredir;

  device = {
    options = {
      vendorId = mkOption {
        type = types.str;
        example = "3553";
      };
      productId = mkOption {
        type = types.str;
        example = "b001";
      };
    };
  };

  usbredir = {
    options = {
      reloadWithUdev = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether reload service on plug in/remove
        '';
      };

      device = mkOption {
        type = types.submodule device;
        default = { };
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
        type = types.enum [ "client" "server" ];
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
      default = { };
    };
  };

  config = {
    systemd.services = builtins.listToAttrs (mapAttrsToList
      (
        name: val:
          let
          in {
            name = "usbredir-${name}";
            value = {
              restartIfChanged = true;
              unitConfig = {
                StartLimitIntervalSec = 0;
              };
              serviceConfig = {
                ExecStart = "${pkgs.usbredir}/bin/usbredirect --device ${val.device.vendorId}:${val.device.productId} ${if val.mode == "client" then "--to" else "--as"} ${val.address}";
                Restart = "always";
                RestartSec = 1;
              };
            };
          }
      )
      cfg);

    services.udev.extraRules = (
      concatStringsSep "\n" (
        mapAttrsToList
          (name: val:
            if val.reloadWithUdev then ''ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="${val.device.vendorId}", ATTR{idProduct}=="${val.device.productId}", TAG+="systemd", RUN+="${pkgs.systemd}/bin/systemctl restart usbredir-${name} --no-block"'' else "")
          cfg
      )
    );
  };
}
