{ pkgs, lib, ...}: 
{
  imports = [
    ./default.nix
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  hardware.pulseaudio.enable = false;

  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    displayManager = {
      defaultSession = "xfce";
      autoLogin = { 
        enable = true;
        user = "virtual";
      };
    };
  };

  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  virtualisation.graphics = true;
  environment.systemPackages = with pkgs; [
    firefox
    xfce.xfce4-clipman-plugin
    xfce.xfce4-weather-plugin
    xfce.xfce4-pulseaudio-plugin
    xfce.xfce4-xkb-plugin
  ];
}