# Turbo

A set of NixOS modules and packages.

## Reason

During our development toward various network and virtualization requirement, we find some missing pieces in the NixOS modules and we build them by ourselves.

After some time we believe that community might find it useful and save some duplicate efforts.

## Quick Start

> checkout [Colmena](https://github.com/zhaofengli/colmena) --- a Nix DevOps Tool

```flake.nix
{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    turbo.url = "git+ssh://git@github.com/wirecatllc/turbo?ref=main";

    colmena.url = "github:zhaofengli/colmena";
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
  };

  outputs = { self, nixpkgs, turbo, colmena, ... }: {
    colmena = import ./hive.nix {
      inherit self turbo;
      pkgs = nixpkgs;
      pkgs-22-05 = nixpkgs-22-05;
    };

    # From Flake but will also processed by flake-compat
    devShell.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = [
        colmena.defaultPackage.x86_64-linux
        nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt
      ];
    };
  };
}
```

```configuration.nix
{
    # use ferm for rule generation
    # https://wirecatllc.github.io/turbo/unstable/reference/networking html#turbonetworkingfirewallenable

    turbo.networking.firewall.enable = true;
    turbo.networking.firewall = {
        ip.filter.chains.forward.rules = [
        {
            interface = "eno1";
            outerface = "wan";
            saddr = "1.1.1.1";
            action = "ACCEPT";
        }
        ];
    };
}
```

## Docs

Right now it is still under heavy construction. Check out the latest here: https://wirecatllc.github.io/turbo/unstable/
