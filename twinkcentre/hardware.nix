{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot = {
    loader.efi.canTouchEfiVariables = true;
    loader.efi.efiSysMountPoint = "/boot";
    kernelParams = [ ];
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    initrd.kernelModules = [ "i915" ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    tmp.cleanOnBoot = true;

    zfs.extraPools = [ "zpool" ];
    supportedFilesystems = [ "zfs" ];

    kernelPackages = pkgs.linuxPackages_6_6; 

    initrd.luks.devices = {
      "cryptroot" = {
        device = "/dev/disk/by-uuid/7197adb3-4b8c-4592-8f22-1f86aa2a5f8d";
        preLVM = true;
        allowDiscards = true;
      };
      "cryptstorage" = {
        device = "/dev/disk/by-uuid/1657901b-c168-4f5d-bf5c-70ed3f4b9a9e";
        preLVM = true;
        allowDiscards = true;
      };
    };
  };
  
  fileSystems."/" =
    { device = "rpool/root";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "rpool/nix";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "zpool/home";
      fsType = "zfs";
      neededForBoot = true; # propagate agenix identities
    };
  
  fileSystems."/virt" =
    { device = "zpool/virt";
      fsType = "zfs";
    };
  
  fileSystems."/data" =
    { device = "zpool/data";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/9013-F29F";
      fsType = "vfat";
    };

  fileSystems."/media/toshiba" =
    { device = "/dev/disk/by-uuid/855811ed-865d-4c94-b441-0acf9c594991";
      fsType = "ext4";
      options = [ "nofail"  ];
    };

  zramSwap.enable = true;
  swapDevices = [ ];
  
  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = true;
  hardware.firmware = with pkgs; [ wireless-regdb ];
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="RU"
  '';

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
