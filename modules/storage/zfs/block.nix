{ lib, config, name, ... }:
with lib;
{
  # Keys can have a maximum of 11 characters
  options = {
    source = mkOption {
      type = types.str;
      description = "Data set name";
    };

    destination = mkOption {
      type = types.str;
      default = "/${config.source}";
    };

    security = mkOption {
      type = types.bool;
      default = true;
      description = "By default, we does not allow exec on host machine";
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };
}
