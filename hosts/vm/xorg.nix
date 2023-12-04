{ stable, inputs, config, pkgs, lib, ... }:

{
  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    displayManager.defaultSession = "xfce";
  };

  environment.systemPackages = with pkgs; [
    xfce.xfce4-clipman-plugin
    xfce.xfce4-weather-plugin
    xfce.xfce4-pulseaudio-plugin
    xfce.xfce4-xkb-plugin
  ];
  
  programs.thunar.enable = lib.mkForce false;
}
