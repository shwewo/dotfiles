{ stable, inputs, config, pkgs, lib, ... }:

{
  environment.sessionVariables = { 
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    #NIXOS_OZONE_WL = "1";
  };

  nixpkgs.overlays = [
    (final: prev: {
      gnome = prev.gnome.overrideScope' (gnomeFinal: gnomePrev: {
        mutter = gnomePrev.mutter.overrideAttrs (old: {
          src = pkgs.fetchgit {
            url = "https://gitlab.gnome.org/vanvugt/mutter.git";
            # GNOME 45: triple-buffering-v4-45
            rev = "0b896518b2028d9c4d6ea44806d093fd33793689";
            sha256 = "sha256-mzNy5GPlB2qkI2KEAErJQzO//uo8yO0kPQUwvGDwR4w=";
          };
        });
      });
    })
  ];

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

  environment.gnome.excludePackages = (with pkgs; [
    gnome-tour
  ]) ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-music
    gnome-terminal
    epiphany # web browser
    geary # email reader
    gnome-characters
    totem # video player
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
    gnome-maps
    gnome-software
    gnome-contacts
    simple-scan
  ]);
}
