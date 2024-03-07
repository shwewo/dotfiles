# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];
 
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.initrd.availableKernelModules = [ "kvm-amd" "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" "nvme" "xhci_pci" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.initrd.luks = {
    yubikeySupport = true;
    devices."cryptroot" = {
      device = "/dev/nvme0n1p2";
      yubikey = {
        slot = 2;
        gracePeriod = 7;
        keyLength = 64;
        saltLength = 16;
        twoFactor = false;
        storage = {
          device = "/dev/nvme0n1p1";
          fsType = "vfat";
          path = "/crypt-storage/default";
        };
      };
    };
  };
  boot.kernelModules = [ "usbip" "kvm-amd" "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" "nvme" "xhci_pci" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ usbip.out ];
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.tmp.cleanOnBoot = true;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/f650daf8-6b92-4a0b-83d7-94b64d4dd189";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/58B4-7151";
      fsType = "vfat";
    };

  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 8*1024;
  } ];

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.bluetooth.enable = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
