# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = 
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  fileSystems."/" = { 
    device = "/dev/sda2"; 
    fsType = "ext4"; 
  };

  fileSystems."/boot/" = { 
    device = "/dev/sda1"; 
    fsType = "vfat"; 
  };

  boot.cleanTmpDir = true;
}
