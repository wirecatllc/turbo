# Guest media is x86_64, independently of the caller's build platform.
# Preserve the original pins; availability of historical downloads varies.
{ pkgs }:
let
  inherit (pkgs) fetchurl;
in
{
  qcow2 = rec {
    debian_13_trixie_genericcloud = fetchurl {
      sha256 = "sha256-JLdsclUV2vI+qt5DI+daGPU4SXHpTMeBxVHFJLuxNNA=";
      url = "https://cloud.debian.org/images/cloud/trixie/20260402-2435/debian-13-generic-amd64-20260402-2435.qcow2";
    };

    debian_12_bookworm_genericcloud = fetchurl {
      sha256 = "sha256-JhNK4V5upxWPJSoblssg4MCoB5+XYMWHXYFvgHFtkSQ=";
      url = "https://cloud.debian.org/images/cloud/bookworm/20240201-1644/debian-12-genericcloud-amd64-20240201-1644.qcow2";
    };

    debian_11_bullseye_genericcloud = fetchurl {
      sha256 = "sha256-lF9/ig85xxUdf8fSBu8Fy10of7/zr0RtbBwuRqj8ues=";
      url = "https://cloud.debian.org/images/cloud/bullseye/20220310-944/debian-11-genericcloud-amd64-20220310-944.qcow2";
    };

    # Compatibility with the original infra spelling.
    debian_11_bulleye_genericcloud = debian_11_bullseye_genericcloud;

    debian_10_buster_genericcloud = fetchurl {
      sha256 = "sha256-ydMEpFlq9FKvyx2NfoPCel5LAbvKd2m++45JQ/qmyic=";
      url = "https://cloud.debian.org/images/cloud/buster/20220911-1135/debian-10-genericcloud-amd64-20220911-1135.qcow2";
    };

    ubuntu_20_04 = fetchurl {
      sha256 = "sha256-D56Dtqc+W705K13gQZPxHku1IGiqMBf6+Bh1VD4mPfY=";
      url = "https://cloud-images.ubuntu.com/releases/focal/release-20220711/ubuntu-20.04-server-cloudimg-amd64-disk-kvm.img";
    };

    ubuntu_22_04 = fetchurl {
      sha256 = "sha256-PsXPWquXv1Bqnzz7CU2meutAnwpcuP2wK6KXM/QdzA0=";
      url = "https://cloud-images.ubuntu.com/releases/22.04/release-20221214/ubuntu-22.04-server-cloudimg-amd64-disk-kvm.img";
    };

    ubuntu_24_04 = fetchurl {
      sha256 = "sha256-eFR9M25Mj5iGT9MIinqzk9erlwiFJjV4QEutf8fF5dg=";
      url = "https://cloud-images.ubuntu.com/releases/24.04/release-20240911/ubuntu-24.04-server-cloudimg-amd64.img";
    };

    ubuntu_26_04 = fetchurl {
      sha256 = "sha256-ncfFNjwBRqCLoMmqg02CwsbfuxxHGtmi8KuhGJ4hvgU=";
      url = "https://cloud-images.ubuntu.com/releases/resolute/release-20260731/ubuntu-26.04-server-cloudimg-amd64.img";
    };

    chr_7_20_8 =
      let
        archive = fetchurl {
          url = "https://download.mikrotik.com/routeros/7.20.8/chr-7.20.8.img.zip";
          sha256 = "sha256-HMKi/3bY6B0jESQ/3zqJFO4Yi/y7ltisJxUg1oLFhdg=";
        };
      in
      # Pin the downloaded archive, not qemu's version-dependent conversion.
      pkgs.runCommand "chr-7.20.8.qcow2"
        { nativeBuildInputs = [ pkgs.unzip pkgs.qemu ]; }
        ''
          unzip ${archive} chr-7.20.8.img
          qemu-img convert -f raw -O qcow2 chr-7.20.8.img "$out"
        '';
  };

  drivers = {
    win_virtio = fetchurl {
      sha256 = "sha256-uKS8ZoNcQwkahdNaELWb2LG2K1XqnwLsdU9ovTLoLA4=";
      url = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso";
    };
  };

  isos = rec {
    livecd = {
      debian-11-3 = fetchurl {
        url = "https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-11.3.0-amd64-standard.iso";
        sha256 = "sha256-crw13V6qU+2CrtqUF/WypsqscL/dm6xs5QnMjIiKPQ4=";
      };

      finnix-124 = fetchurl {
        url = "https://www.finnix.org/releases/124/finnix-124.iso";
        sha256 = "sha256-7MAZ6y+xzGYSAh47AQiAE2e6rcWycEhSqw8/s3OTIoc=";
      };
    };

    ubuntu_desktop_20-04-3 = fetchurl {
      sha256 = "sha256-X968Q13tRq6ZE2yoda/G8FveIXvn3QGOGEGST3HbRrU=";
      url = "https://releases.ubuntu.com/20.04.3/ubuntu-20.04.3-desktop-amd64.iso";
    };

    archlinux = date: sha1: fetchurl {
      inherit sha1;
      url = "https://mirrors.edge.kernel.org/archlinux/iso/${date}/archlinux-${date}-x86_64.iso";
    };
    # Arch is rolling basis, so release will become unavailable once a while
    # https://archlinux.org/releng/releases/
    archlinux_latest = archlinux "2025.04.01" "sha1-MnrVdTdAIOD2090/pKCshvDj5L8=";

    ubuntu_20_04_1_LTS = fetchurl {
      sha256 = "443511f6bf12402c12503733059269a2e10dec602916c0a75263e5d990f6bb93";
      url = "https://releases.ubuntu.com/20.04.1/ubuntu-20.04.1-live-server-amd64.iso";
    };

    netbootxyz = fetchurl {
      url = "https://boot.netboot.xyz/ipxe/netboot.xyz.iso";
      sha1 = "276089a7cd8edb5ba64e10bae9097a7fa34a678a";
    };

    alpine = fetchurl {
      url = "https://dl-cdn.alpinelinux.org/alpine/v3.13/releases/x86_64/alpine-standard-3.13.1-x86_64.iso";
      sha256 = "1zvcm7z5avhfkq3fvci0r6rifdh7j7lpy4rlrsrq6bd3hs1jmzsd";
    };

    debian_12_1_0 = fetchurl {
      url = "https://cdimage.debian.org/mirror/cdimage/archive/12.1.0/amd64/iso-dvd/debian-12.1.0-amd64-DVD-1.iso";
      sha256 = "sha256-kWj/U9eJU3209SM+ffpehgUZxEtoEytwgFIY+EKwAEE=";
    };

    centos_7_minimal_2009 = fetchurl {
      url = "http://mirrors.ocf.berkeley.edu/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso";
      sha256 = "sha256-B7lOaxoLAmC5TIPWu3aya/ejENx416nHQygJ+5vGGUo=";
    };
  };
}
