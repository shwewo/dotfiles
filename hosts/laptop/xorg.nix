{ stable, inputs, config, pkgs, lib, ... }:

{
  environment.sessionVariables = { 
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  };
  
  services.xserver = {
    enable = true;
    wacom.enable = true;
    videoDrivers = [ "amdgpu" ];
    displayManager = {
      gdm.enable = true;
      defaultSession = "gnome";
    };
    desktopManager = {
      gnome.enable = true;
    };
    # displayManager.defaultSession = "xfce";
    # config = ''
    #   section "OutputClass"
    #   Identifier "AMD"
    #   MatchDriver "amdgpu"
    #   Driver "amdgpu"
    #   Option "TearFree" "true"
    #   EndSection

    #   Section "InputClass"
    #   Identifier "Tablet"
    #   Driver "wacom"
    #   MatchDevicePath "/dev/input/event*"
    #   MatchUSBID "056a:037a"
    #   EndSection
    # '';
  };

  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnomeExtensions.activate-window-by-title
    gnomeExtensions.unite
    gnomeExtensions.tailscale-qs
    gnomeExtensions.gsconnect
    gnomeExtensions.clipboard-indicator
    gnome.gnome-tweaks
    mojave-gtk-theme
    adw-gtk3
    # xfce.xfce4-clipman-plugin
    # xfce.xfce4-weather-plugin
    # xfce.xfce4-pulseaudio-plugin
    # xfce.xfce4-xkb-plugin
    # xfce.xfce4-timer-plugin
  ];
}
