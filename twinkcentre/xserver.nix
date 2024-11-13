{ pkgs, lib, ... }: 

{
  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
    desktopManager.xterm.enable = false;
    displayManager.gdm.enable = true;
    displayManager.gdm.autoSuspend = false;
  };

  services.xrdp = {
    enable = true;
    defaultWindowManager = "${pkgs.gnome-session}/bin/gnome-session";
    openFirewall = true;
    audio.enable = true;
    # extraConfDirCommands = ''
    #   substituteInPlace $out/sesman.ini \
    #     --replace-warn "KillDisconnected=false" "KillDisconnected=true" \
    #     --replace-warn "DisconnectedTimeLimit=0" "DisconnectedTimeLimit=30"
    # '';
  };

  services.pipewire.audio.enable = lib.mkForce false;
  services.pipewire.pulse.enable = lib.mkForce false;
  services.pipewire.alsa.enable = lib.mkForce false;
  hardware.pulseaudio.enable = true;
  hardware.graphics.enable = true;

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  environment.systemPackages = with pkgs; [
    firefox
    cage
    sway
    foot
    waypipe
    papirus-icon-theme
  ];
}
