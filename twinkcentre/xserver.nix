{ pkgs, lib, ... }: 

{
  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    displayManager.defaultSession = "xfce";
  };

  services.xrdp = {
    enable = true;
    defaultWindowManager = "xfce4-session";
    openFirewall = true;
    audio.enable = true;
    extraConfDirCommands = ''
      substituteInPlace $out/sesman.ini \
        --replace-warn "KillDisconnected=false" "KillDisconnected=true" \
        --replace-warn "DisconnectedTimeLimit=0" "DisconnectedTimeLimit=30"
    '';
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
    cage
    sway
    foot
    waypipe
    papirus-icon-theme
  ];
}
