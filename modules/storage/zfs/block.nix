{ lib, config, name, ... }:
with lib;
{
  # Keys can have a maximum of 11 characters
  options = {
    source = mkOption {
      type = types.str;
      description = ''
        Data set name
      '';
    };

    destination = mkOption {
      type = types.str;
      default = "/${config.source}";
      defaultText = lib.literalExpression "/\${config.source}";
      description = ''
        Mount point destination
      '';
    };

    security = mkOption {
      type = types.bool;
      default = true;
      description = "By default, we do not allow guest file exec on host machine";
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Extra options to pass to FileSystems.options
      '';
    };
  };
}
