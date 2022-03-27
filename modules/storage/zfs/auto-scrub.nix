{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.turbo.storage.zfs;
  hasZFS = any (d: d.fsType == "zfs") (attrValues config.fileSystems);
in
{
  options = {
    turbo.storage.zfs = {
      autoScrub = mkOption {
        type = types.bool;
        default = hasZFS;
      };
    };
  };

  config = {
    services.zfs.autoScrub.enable = mkDefault cfg.autoScrub;
  };
}