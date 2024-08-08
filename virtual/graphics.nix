{ pkgs, lib, inputs, unstable, ...}: 
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
      gnome.enable = true;
    };
    displayManager = {
      defaultSession = "gnome";
      autoLogin = { 
        enable = true;
        user = "virtual";
      };
      gdm.enable = true;
    };
  };

  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  virtualisation.graphics = true;
  environment.systemPackages = with pkgs; [
  ];
}