{ pkgs, lib, config, ... }:
let
  cfg = config.turbo.networking.routing.rtr;
  superCfg = config.turbo.networking.router;
  types = lib.types;
in {
  options = {
    turbo.networking.routing.rtr = {
      enable = lib.mkOption {
        description = "Run RPKI RTR daemon";
        type = types.bool;
        default = false;
      };
      publicKey = lib.mkOption {
        description = "Path to RPKI cache signing key";
        type = types.path;
        default = ./cf.pub;
      };
      port = lib.mkOption {
        description = "Port to listen on";
        type = types.ints.unsigned;
        default = 8282;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.gortr = {
      description = "GoRTR";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.gortr}/bin/gortr -verify.key ${cfg.publicKey} -bind :${toString cfg.port}";
      };
    };
  };
}
