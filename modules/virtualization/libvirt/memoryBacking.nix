{ lib, ... }:
with lib;
let
  allocationModule = {
    options = {
      mode = mkOption {
        type = types.nullOr (types.enum ["immediate" "ondemand"]);
        default = null;
      };
      threads = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
    };
  };
in
{
  options = {
    sourceType = mkOption {
      type = types.nullOr (types.enum [ "memfd" "file" "anonymous" ]);
      default = null;
    };

    accessMode = mkOption {
      type = types.enum [ "shared" "private" ];
      default = "shared";
    };

    hugepages = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "add xml def or empty string to enable";
    };

    nosharepages = mkOption {
      type = types.bool;
      default = false;
    };

    locked = mkOption {
      type = types.bool;
      default = false;
    };

    allocation = mkOption {
      type = types.nullOr (types.submodule allocationModule);
      default = null;
    };

    discard = mkOption {
      type = types.bool;
      default = false;
    };
  };
}
