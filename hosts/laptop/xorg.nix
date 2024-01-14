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
    xfce.xfce4-xkb-plugin
    xfce.xfce4-timer-plugin
  ];
  
  i18n.inputMethod = {
    # enabled = "fcitx5";
    # fcitx5.addons = with pkgs; [
    #   fcitx5-rime
    #   fcitx5-chinese-addons
    # ];

    # 我现在用 ibus
    enabled = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      libpinyin
      rime
    ];
  };
  programs.thunar.enable = lib.mkForce false;
}
