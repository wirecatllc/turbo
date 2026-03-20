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
          Our private key (inline). Mutually exclusive with privateKeyFile.
        '';
        type = types.nullOr types.str;
        default = null;
      };
      privateKeyFile = lib.mkOption {
        description = ''
          Path to a file containing the private key. Mutually exclusive with privateKey.
          Preferred over privateKey as it avoids storing the key in the Nix store.
        '';
        # types.str intentional: types.path would copy the key into the Nix store
        type = types.nullOr types.str;
        default = null;
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
        default = [ ];
      };
    };
  };
in
{
  imports = [
    ./kernel.nix
    ./userspace.nix
  ];
  config = {
    assertions = lib.concatLists (lib.mapAttrsToList (name: tunnel: [
      {
        assertion = (tunnel.privateKey != null) != (tunnel.privateKeyFile != null);
        message = "wireguard tunnel '${name}': exactly one of privateKey or privateKeyFile must be set.";
      }
    ]) cfg.tunnels);
  };
  options = {
    turbo.networking.wireguard = {
      backend = lib.mkOption {
        description = ''
          Backend to use

          Defaults to userspace (boringtun) for containers, and
          kernel (systemd-networkd) otherwise.
        '';
        type = types.enum [ "kernel" "userspace" ];
        defaultText = lib.literalExpression ''if config.boot.isContainer then "userspace" else "kernel"'';
        default = if config.boot.isContainer then "userspace" else "kernel";
      };
      tunnels = lib.mkOption {
        description = ''
          Tunnels
        '';
        type = types.attrsOf tunnelType;
        default = { };
      };
    };
  };
}
