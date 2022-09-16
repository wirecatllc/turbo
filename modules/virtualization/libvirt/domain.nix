{ lib, ... }:
with lib;
let
  supportedModules = {
    vcpu = ./cpu/vcpu.nix;
    cputune = ./cpu/cputune.nix;
    os = ./os.nix;
    features = ./features.nix;
    memory = ./memory.nix;
    device = ./device;
    memoryBacking = ./memoryBacking.nix;
  };

  modules = attrsets.mapAttrs (n: v: types.submodule v) supportedModules;

in
{
  options = {
    uuid = mkOption {
      description = "Machine UUID";
      type = types.str;
      example = "509ee912-24b8-11eb-96f4-1b7af47272c3";
    };

    title = mkOption {
      type = types.nullOr types.str;
      description = ''
        The optional element title provides space for a short description of the domain. The title should not contain any newlines. Since 0.9.10 .
      '';
      example = "A string with no newline";
      default = null;
    };

    type = mkOption {
      type = types.enum [ "xen" "kvm" "qemu" "lxc" ];
      description = ''
        The type specifies the hypervisor used for running the domain. The allowed values are driver specific, but include "xen", "kvm", "qemu" and "lxc".
      '';
      default = "kvm";
    };

    vcpu = mkOption {
      type = modules.vcpu;
      description = ''
        CPU Allocation
      '';
      default = { };
    };

    os = mkOption {
      type = modules.os;
      description = ''
        OS setting
      '';
      default = { };
    };

    cputune = mkOption {
      type = types.nullOr modules.cputune;
      description = ''
        CPU Tune
      '';
      default = null;
    };

    features = mkOption {
      type = modules.features;
      description = "feature type";
      default = { };
    };

    memory = mkOption {
      type = modules.memory;
      description = "memory";
      default = { };
    };

    devices = lib.mkOption {
      description = "device type";
      type = modules.device;
      default = { };
    };

    memoryBacking = lib.mkOption {
      description = "Memory Backing";
      type = types.nullOr modules.memoryBacking;
      default = null;
    };

    extraConfig = lib.mkOption {
      description = "extra xml to add in domain";
      type = types.str;
      default = "";
    };
  };
}
