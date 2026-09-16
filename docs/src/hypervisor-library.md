# Hypervisor library

Turbo exports VM image and installer helpers independently of its NixOS modules:

```nix
let
  library = turbo.lib.hypervisor { inherit pkgs; };
in {
  # Example values for a consumer's VM configuration:
  diskImage = library.qcow2.debian_13_trixie_genericcloud;
  seedImage = library.cloud-config {
    meta_data = "instance-id: example-vm\nlocal-hostname: example-vm\n";
    user_data = ''
      #cloud-config
      users:
        - name: operator
          ssh_authorized_keys:
            - ssh-ed25519 AAAA...replace-with-your-public-key
    '';
    network_config = ''
      version: 2
      ethernets:
        eth0:
          dhcp4: true
    '';
  };
}
```

For a non-flake import, use `(import /path/to/turbo/lib).hypervisor { inherit pkgs; }`.
The caller supplies `pkgs`, so helpers use the caller's nixpkgs revision, overlays,
and build platform. Importing the library neither enables services nor downloads
images. There is no overlay or NixOS module argument to configure.

## Cloud-init seed images

`cloud-config { user_data; meta_data ? ""; network_config ? null; }` returns an ISO
file derivation labeled `cidata`, following the
[NoCloud format](https://docs.cloud-init.io/en/latest/reference/datasources/nocloud.html).
Inputs are strings containing the already serialized configuration. `user-data`
and `meta-data` are always present; `network-config` is omitted when null and is
included even when an explicitly supplied string is empty. Supply a unique
`instance-id` in metadata when provisioning a VM.

`cloud-installer { user_data; }` is shorthand for a seed with empty metadata and
no network configuration. Both helpers preserve input bytes, including trailing
newlines, and support large payloads without passing them in environment variables.
They package data without validating the guest's cloud-init schema.

These derivations put their contents in the Nix store. Do not put private keys,
passwords, or other secrets in them.

## Image catalog

The `qcow2`, `drivers`, and `isos` attribute sets carry the public image pins from
infra's hypervisor library. The catalog contains x86_64 guest media; selecting an
ARM build platform does not turn those downloads into ARM guest images. Build
NixOS installers with a Linux `pkgs` matching the guest architecture.

- `qcow2`: Debian 10–13, Ubuntu 20.04–26.04, and MikroTik CHR 7.20.8.
- `drivers.win_virtio`: Windows virtio drivers.
- `isos`: Debian, Ubuntu, Alpine, CentOS, Arch, netboot.xyz, and rescue media in
  `isos.livecd`.

Release versions and download pins are retained for migration compatibility.
CHR pins the downloaded ZIP and converts it in a separate derivation, so a
change in the caller's QEMU version does not cause a fixed-output hash mismatch.
The corrected name
`qcow2.debian_11_bullseye_genericcloud` also has the original
`debian_11_bulleye_genericcloud` alias. Despite its historical name,
`debian_13_trixie_genericcloud` retains infra's Debian 13 **generic** image.
`isos.archlinux` retains the curried `date: sha1: ...` API.

Historical pins are not recommendations of current or supported operating
systems. Some upstreams remove old releases or replace files at mutable URLs
(including `win_virtio`, `netbootxyz`, and `archlinux_latest`). Hashes prevent
silently accepting changed content, but a download may fail. This migration does
not refresh the catalog or require downloading it during checks.

## NixOS installer

`isos.nixos extraConfig` accepts a NixOS module (an attribute set, function, or
module path) and returns the store path of the ISO file, retaining its derivation
context. It includes the minimal installer and channel modules, with documentation
disabled by default. Caller settings can override these defaults.

```nix
library.isos.nixos ({ lib, ... }: {
  image.baseName = lib.mkForce "rescue";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA...replace-with-your-public-key"
  ];
})
```

On older nixpkgs (including Turbo's own pin), set `isoImage.isoName =
lib.mkForce "rescue.iso"` instead. The path comes from the evaluated NixOS
configuration, including the `.zst` suffix when `isoImage.compressImage` is true.
Turbo includes no operator keys or organization specific access policy.

## Migration plan

1. Land the Turbo library and its checks. Existing infra consumers remain unchanged.
2. Update infra's Turbo lock and replace each local library import with
   `turbo.lib.hypervisor { inherit pkgs; }`, passing the Turbo input to modules as
   needed. Existing `cloud-config`, image, and `isos.nixos` expressions can stay.
3. Keep infra's `isos.nixos-wirecat` preset and the privately hosted `windows_7`
   and `windows_2012` images in a local wrapper. Extend Turbo's `isos` attribute set
   with these values, using `library.isos.nixos` for the Wirecat installer.
4. Evaluate affected VM definitions and build representative seed images before
   removing the shared implementation from infra.

The cloud-init helpers no longer append an extra newline to input. Existing Nix
multiline YAML strings work unchanged; callers needing a trailing newline must
include it. The NixOS helper now returns the configured ISO filename rather than
guessing it from the derivation name.

## Checks

Run on Linux or with a Linux remote builder:

```console
nix build .#checks.x86_64-linux.hypervisor-cloud-init .#checks.x86_64-linux.hypervisor-api
```

The first check reads real ISO contents, including a large payload and both
optional-network cases. The second evaluates the catalog and NixOS filename
handling without fetching the guest images or building an installer.
