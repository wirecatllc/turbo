{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.turbo.storage.zfs;
in
{
  options = {
    turbo.storage.zfs = {
      block = mkOption {
        type = types.attrsOf (types.submodule ./block.nix);
        default = { };
        example = ''
          "user1-dataset1" = {
              source = "tank/user/dataset-1";
          };
        '';
        description = ''
          This section is used to manage Client's block storage on Hosting machine.
          Block stated here will be mounted with recommended block storage strategy and policy applied.
        '';
      };
    };
  };

  config = {
    fileSystems = lib.mapAttrs'
      (n: v: {
        name = "${v.destination}";
        value = {
          device = v.source;
          fsType = "zfs";
          options = [
            "nofail"
          ] ++ (lib.optionals v.security [
            "noexec"
            "nosuid"
          ]) ++ v.extraOptions;
        };
      })
      cfg.block;
  };

  imports = [
    ./auto-scrub.nix
  ];
}
