{ pkgs, lib, ... }: 
let 
  gnome = import ./gnome.nix;
in {
  services.xserver = {
    enable = true;
    wacom.enable = true;
    videoDrivers = [ "amdgpu" ];
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
    displayManager.defaultSession = "gnome";
  };
}