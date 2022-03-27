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
