{ ... }: 

{
  imports = [
    ../generics/gnome.nix
  ];

  services.xserver = {
    enable = true;
    wacom.enable = true;
    videoDrivers = [ "amdgpu" ];
    desktopManager.gnome.enable = true;
    desktopManager.xterm.enable = false;
    displayManager.gdm.enable = true;
    displayManager.defaultSession = "gnome";
  };
}