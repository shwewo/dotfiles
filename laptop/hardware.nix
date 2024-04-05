{ pkgs, lib, config, modulesPath, stable, unstable, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.initrd.availableKernelModules = [ "kvm-amd" "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" "nvme" "xhci_pci" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  # boot.initrd.luks = {
  #   yubikeySupport = true;
  #   devices."cryptroot" = {
  #     device = "/dev/nvme0n1p2";
  #     yubikey = {
  #       slot = 2;
  #       gracePeriod = 7;
  #       keyLength = 64;
  #       saltLength = 16;
  #       twoFactor = false;
  #       storage = {
  #         device = "/dev/nvme0n1p1";
  #         fsType = "vfat";
  #         path = "/crypt-storage/default";
  #       };
  #     };
  #   };
  # };
  boot.kernelModules = [ "usbip" "kvm-amd" "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" "nvme" "xhci_pci" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ usbip.out ];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r hnw19r/local/root@blank
  '';

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7D7A-9385";
    fsType = "vfat";
  };

  fileSystems."/" = {
    device = "hnw19r/local/root";
    fsType = "zfs";
  };

  fileSystems."/nix" = {
    device = "hnw19r/local/nix";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "hnw19r/safe/home";
    fsType = "zfs";
  };

  fileSystems."/persist" = {
    device = "hnw19r/safe/persist";
    fsType = "zfs";
  };

  # fileSystems."/" =
  #   { device = "/dev/disk/by-uuid/f650daf8-6b92-4a0b-83d7-94b64d4dd189";
  #     fsType = "ext4";
  #   };

  # fileSystems."/boot" =
  #   { device = "/dev/disk/by-uuid/58B4-7151";
  #     fsType = "vfat";
  #   };

  zramSwap.enable = true;

  # 5 GHZ wifi hotspot
  hardware.firmware = with pkgs; [ wireless-regdb ];
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="RU"
  '';

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.bluetooth.enable = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
