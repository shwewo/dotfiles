{ stable, inputs, config, pkgs, lib, ... }:

{
  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    wacom.enable = true;
    videoDrivers = [ "amdgpu" ];
    displayManager.defaultSession = "xfce";
    config = ''
      section "OutputClass"
      Identifier "AMD"
      MatchDriver "amdgpu"
      Driver "amdgpu"
      Option "TearFree" "true"
      EndSection

      Section "InputClass"
      Identifier "Tablet"
      Driver "wacom"
      MatchDevicePath "/dev/input/event*"
      MatchUSBID "056a:037a"
      EndSection
    '';
  };

  environment.systemPackages = with pkgs; [
    xfce.xfce4-clipman-plugin
    xfce.xfce4-weather-plugin
    xfce.xfce4-pulseaudio-plugin
  ];

  programs.thunar.enable = lib.mkForce false;
}