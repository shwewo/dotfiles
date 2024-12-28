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
  };


  services.displayManager.defaultSession = "gnome";

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.pulseaudio.enable = false;
  hardware.graphics.enable = true;
}
