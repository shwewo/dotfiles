{ pkgs, lib, inputs, ... }:

{
  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      gnome.enable = true;
    };
    displayManager = {
      defaultSession = "gnome";
      autoLogin = { 
        enable = true;
        user = "cute";
      };
      gdm.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    firefox
    xfce.xfce4-clipman-plugin
    xfce.xfce4-weather-plugin
    xfce.xfce4-pulseaudio-plugin
    xfce.xfce4-xkb-plugin
    inputs.chromium-gost.packages.${pkgs.system}.default
  ];

  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
}
