{ lib, ... }:
with lib;
let
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
  };
}
