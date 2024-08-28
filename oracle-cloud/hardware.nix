{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
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
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  nixpkgs.buildPlatform = lib.mkDefault "x86_64-linux";
}
