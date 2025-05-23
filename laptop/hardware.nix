{ pkgs, lib, config, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  
  boot.initrd.availableKernelModules = [ "kvm-amd" "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" "nvme" "xhci_pci" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "usbip" "kvm-amd" "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" "nvme" "xhci_pci" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ usbip.out v4l2loopback ];
  boot.kernelPackages = pkgs.linuxPackages_6_6;

  boot.initrd.luks = {
    yubikeySupport = false;
    devices."cryptroot" = {
      device = "/dev/disk/by-uuid/b81f1605-968a-4db0-9a1d-4d32d749567b";
      preLVM = true;
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

  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zpool import zpool
    zfs rollback -r zpool/root@blank
  '';

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7D7A-9385";
    fsType = "vfat";
  };
  
  fileSystems."/" = {
    device = "zpool/root";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "zpool/home";
    fsType = "zfs";
  };
  
  fileSystems."/persist" = {
    device = "zpool/persist";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/virt" = {
    device = "zpool/virt";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "zpool/nix";
    fsType = "zfs";
  };

  fileSystems."/media" = {
    device = "zpool/media";
    fsType = "zfs";
  };

  zramSwap.enable = true;
  swapDevices = [ { device = "/dev/nvme0n1p2"; randomEncryption.enable = true; } ];

  # 5 GHZ wifi hotspot
  hardware.firmware = with pkgs; [ wireless-regdb ];
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="RU"
  '';

  hardware.bluetooth.enable = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
