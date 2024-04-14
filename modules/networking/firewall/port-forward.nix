{ config, pkgs, lib, ... }:
with lib;
with builtins;
let
  mkFilter = description: mkOption {
    inherit description;
    default = null;
    type = types.nullOr (
      types.enum [ "tcp" "udp" ]
    );
  };
  # Note: only one port is allowed in each forward
  portForwardType = types.submodule {
    options = {
      srcPort = mkOption {
        type = types.ints.unsigned;
        description = "Inbound dst port";
        example = 22;
      };
      dstPort = mkOption {
        type = types.ints.unsigned;
        description = "Outbound dst port";
        example = 22;
      };
      interface = mkOption {
        type = types.str;
        example = "eth0";
        default = "";
        description = "Inbound interface";
      };
      dstIp = mkOption {
        type = types.str;
        example = "192.168.1.100";
        description = "Forward to which host";
      };
      protocol = mkFilter "What protocol to forward";
    };
  };
  cfg = config.turbo.networking.firewall;
in
{
  options.turbo.networking.firewall = {
    portForward = mkOption {
      type = types.listOf portForwardType;
      default = [ ];
      description = ''
        A list of port-forward rules to render
      '';
    };
  };

  config.turbo.networking.firewall = {
    # Port forward
    # It forwards all traffic from interface and port to specified ip and port
    extraConfigs = mkIf (cfg.portForward != [ ]) [
      (
        # UDP port forward: do not rewrite source IP, so client could send back response to correct IP
        ''
          @def &FORWARD_PORT($proto, $srcIf, $srcPort, $dstIp, $dstPort) = {
              table filter chain FORWARD interface $srcIf daddr $dstIp proto $proto dport $dstPort ACCEPT;
              table nat chain PREROUTING interface $srcIf proto $proto dport $srcPort DNAT to "$dstIp:$dstPort";
              table nat chain POSTROUTING proto $proto daddr $dstIp dport $dstPort MASQUERADE; 
          }

          @def &FORWARD_PORT_UDP($proto, $srcIf, $srcPort, $dstIp, $dstPort) = {
              table filter chain FORWARD interface $srcIf daddr $dstIp proto $proto dport $dstPort ACCEPT;
              table nat chain PREROUTING interface $srcIf proto $proto dport $srcPort DNAT to "$dstIp:$dstPort";
          }
        '' + (
          let
            # Render a single argument or a list
            argument = arg:
              if isList arg then
                "(" + concatStringsSep " " (map argument arg) + ")"
              else toString arg;

            strJoin = str: l: (foldl (a: b: a + str + b) "" l);
            genPortForward = pf: "&FORWARD_PORT${if pf.protocol == "udp" then "_UDP" else ""}(${argument pf.protocol}, ${pf.interface}, ${toString pf.srcPort}, ${pf.dstIp}, ${toString pf.dstPort});";
            forwards = map genPortForward cfg.portForward;
          in
          strJoin "\n" forwards
        )
      )
    ];
  };
}
