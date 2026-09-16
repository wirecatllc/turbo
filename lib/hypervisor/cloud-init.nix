{ pkgs }:
let
  # NoCloud requires user-data and meta-data; network-config is optional.
  # Passing data through files avoids shell interpretation and environment limits.
  cloud-config = { user_data, meta_data ? "", network_config ? null }:
    pkgs.runCommand "cloud-config.iso"
      ({
        inherit user_data meta_data;
        passAsFile = [ "user_data" "meta_data" ]
          ++ pkgs.lib.optional (network_config != null) "network_config";
        nativeBuildInputs = [ pkgs.cdrkit ];
      } // pkgs.lib.optionalAttrs (network_config != null) {
        inherit network_config;
      }) ''
      cp "$user_dataPath" user-data
      cp "$meta_dataPath" meta-data
      ${pkgs.lib.optionalString (network_config != null) ''
        cp "$network_configPath" network-config
      ''}
      genisoimage -output "$out" -volid cidata -joliet -rock \
        user-data meta-data ${pkgs.lib.optionalString (network_config != null) "network-config"}
    '';
in
{
  inherit cloud-config;
  cloud-installer = { user_data }: cloud-config { inherit user_data; };
}
