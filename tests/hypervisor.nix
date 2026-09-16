{ pkgs, hypervisor }:
let
  inherit (pkgs) lib;
  library = hypervisor { inherit pkgs; };
  userData = ''
    #cloud-config
    write_files:
      - path: /etc/example
        content: |
          literal $HOME $(touch should-not-exist) `id` "quotes" \\backslash
          UTF-8: café
  '';
  metaData = "instance-id: turbo-test\nlocal-hostname: turbo-test\n";
  networkConfig = "version: 2\nethernets: {}\n";
  # Exceeds Linux's per-environment-variable limit of 128 KiB.
  largeData = lib.concatStrings (builtins.genList (_: userData) 10000);
  seed = library.cloud-config {
    user_data = userData;
    meta_data = metaData;
    network_config = networkConfig;
  };
  installer = library.cloud-installer { user_data = userData; };
  largeSeed = library.cloud-config { user_data = largeData; };
  emptyNetworkSeed = library.cloud-config {
    user_data = "-n";
    network_config = "";
  };
  customModule = { lib, options, ... }: {
    config =
      if options ? image.baseName then {
        image.baseName = lib.mkForce "turbo-custom-installer";
      } else {
        isoImage.isoName = lib.mkForce "turbo-custom-installer.iso";
      };
  };
  customIso = library.isos.nixos customModule;
  compressedIso = library.isos.nixos {
    imports = [ customModule ];
    isoImage.compressImage = true;
  };
  defaultIso = library.isos.nixos { };
  media = builtins.attrValues library.qcow2
    ++ builtins.attrValues library.drivers
    ++ builtins.attrValues (removeAttrs library.isos [ "livecd" "archlinux" "nixos" ])
    ++ builtins.attrValues library.isos.livecd;
in
{
  hypervisor-cloud-init = pkgs.runCommand "hypervisor-cloud-init-check"
    { nativeBuildInputs = [ pkgs.cdrkit ]; }
    ''
      check_file() {
        isoinfo -R -i "$1" -x "/$2" > actual
        cmp "$3" actual
      }
      check_label() {
        isoinfo -d -i "$1" | grep -q '^Volume id: cidata$'
      }
      check_label ${seed}
      check_file ${seed} user-data ${pkgs.writeText "user-data" userData}
      check_file ${seed} meta-data ${pkgs.writeText "meta-data" metaData}
      check_file ${seed} network-config ${pkgs.writeText "network-config" networkConfig}

      check_label ${installer}
      check_file ${installer} user-data ${pkgs.writeText "user-data" userData}
      check_file ${installer} meta-data ${pkgs.writeText "empty" ""}
      isoinfo -R -f -i ${installer} > files
      test "$(sort files)" = "$(printf '/meta-data\n/user-data')"

      check_file ${largeSeed} user-data ${pkgs.writeText "large-user-data" largeData}
      check_file ${emptyNetworkSeed} user-data ${pkgs.writeText "no-newline" "-n"}
      check_file ${emptyNetworkSeed} network-config ${pkgs.writeText "empty" ""}
      isoinfo -R -f -i ${emptyNetworkSeed} | grep -q '^/network-config$'
      touch "$out"
    '';

  # Evaluate media without downloading historical images or building a NixOS ISO.
  hypervisor-api =
    assert lib.all lib.isDerivation media;
    assert builtins.deepSeq (map (image: image.drvPath) media) true;
    assert library.qcow2.debian_11_bulleye_genericcloud == library.qcow2.debian_11_bullseye_genericcloud;
    assert lib.isDerivation (library.isos.archlinux "2025.04.01" "sha1-MnrVdTdAIOD2090/pKCshvDj5L8=");
    assert lib.hasSuffix "/iso/turbo-custom-installer.iso" customIso;
    assert lib.hasSuffix ".iso" defaultIso;
    assert lib.hasSuffix "/iso/turbo-custom-installer.iso.zst" compressedIso;
    assert builtins.hasContext customIso;
    pkgs.runCommand "hypervisor-api-check" { } ''
      touch "$out"
    '';
}
