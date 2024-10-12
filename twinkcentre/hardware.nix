{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.kernelPackages =   
  with builtins; with lib; let
    latestCompatibleVersion = config.boot.zfs.package.latestCompatibleLinuxPackages.kernel.version;
    xanPackages = filterAttrs (name: packages: hasSuffix "_xanmod" name && (tryEval packages).success) pkgs.linuxKernel.packages;
    compatiblePackages = filter (packages: compareVersions packages.kernel.version latestCompatibleVersion <= 0) (attrValues xanPackages);
    orderedCompatiblePackages = sort (x: y: compareVersions x.kernel.version y.kernel.version > 0) compatiblePackages;
  in head orderedCompatiblePackages;

  boot.initrd.luks.devices = {
    "cryptroot" = {
      device = "/dev/disk/by-uuid/7197adb3-4b8c-4592-8f22-1f86aa2a5f8d";
      preLVM = true;
      allowDiscards = true;
    };
  };
  environment.etc.crypttab.text = ''
    cryptstorage UUID=1657901b-c168-4f5d-bf5c-70ed3f4b9a9e /etc/luks-keys/samsung.key
  '';

  boot.zfs.extraPools = [ "zpool" ];
  boot.supportedFilesystems = [ "zfs" ];
  
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
    };
  
  fileSystems."/media" =
    { device = "zpool/media";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/9013-F29F";
      fsType = "vfat";
    };

  zramSwap.enable = true;
  swapDevices = [ ];
  
  hardware.bluetooth.enable = true;
  hardware.firmware = with pkgs; [ wireless-regdb ];
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="RU"
  '';

  boot.tmp.cleanOnBoot = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
