{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "virtio_pci" "usbhid" "kvm" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "bochs_drm" "kvm" ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [
    "console=ttyS0"
    "console=tty1"
    "nvme.shutdown_timeout=10"
    "libiscsi.debug_libiscsi_eh=1"
  ];
  
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/402d94d4-8291-4341-bb2c-8af553476cab";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/1DDB-9CC9";
      fsType = "vfat";
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
