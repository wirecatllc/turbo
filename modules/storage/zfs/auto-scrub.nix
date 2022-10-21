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
        defaultText = lib.literalExpression ''any (d: d.fsType == "zfs") (attrValues config.fileSystems);'';
        description = ''
         whether to enable ZFS auto scrub for given storage. This is suggested to keep data integraty
        '';
      };
    };
  };

  config = {
    services.zfs.autoScrub.enable = mkDefault cfg.autoScrub;
  };
}
