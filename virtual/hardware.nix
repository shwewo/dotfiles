{ config, lib, pkgs, modulesPath, ... }:

{
  imports = 
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  fileSystems."/" = { 
    device = "/dev/sda2"; 
    fsType = "ext4"; 
  };

  fileSystems."/boot/" = { 
    device = "/dev/sda1"; 
    fsType = "vfat"; 
  };

  boot.tmp.cleanOnBoot = true;
}