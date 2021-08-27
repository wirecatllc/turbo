{ pkgs, lib, config, ... }:
with builtins;

# networkd is required for link-local configuration
# (maybe move to ngtun?)
let
  cfg = config.turbo.networking.wireguard;
  types = lib.types;

  tunnelType = types.submodule {
    options = {
      privateKey = lib.mkOption {
        description = ''
          Our private key
        '';
        type = types.str;
      };
      listenPort = lib.mkOption {
        description = ''
          Port to listen on
        '';
        type = types.ints.unsigned;
      };
      fwMark = lib.mkOption {
        description = ''
          Firewall mark
        '';
        type = types.ints.unsigned;
      };
      peers = lib.mkOption {
        description = ''
          Peers
        '';

        # Not attrsOf to disallow merging
        type = types.listOf peerType;
      };
    };
  };
  peerType = types.submodule {
    options = {
      endpoint = lib.mkOption {
        description = ''
          Endpoint
        '';
        type = types.nullOr types.str;
        default = null;
      };
      publicKey = lib.mkOption {
        description = ''
          Peer public key
        '';
        type = types.str;
      };
      persistentKeepalive = lib.mkOption {
        description = ''
          Value of PersistentKeepalive

          0 means persistent keep-alive is disabled.
        '';
        type = types.ints.unsigned;
        default = 0;
      };
      allowedIPs = lib.mkOption {
        description = ''
          Allowed IPs
        '';
        type = types.listOf types.str;
        default = [];
      };
    };
  };
in
{
  imports = [
    ./kernel.nix
    ./userspace.nix
  ];
  options = {
    turbo.networking.wireguard = {
      backend = lib.mkOption {
        description = ''
          Backend to use

          Defaults to userspace (boringtun) for containers, and
          kernel (systemd-networkd) otherwise.
        '';
        type = types.enum [ "kernel" "userspace" ];
        default = if config.boot.isContainer then "userspace" else "kernel";
      };
      tunnels = lib.mkOption {
        description = ''
          Tunnels
        '';
        type = types.attrsOf tunnelType;
        default = {};
      };
    };
  };
}
