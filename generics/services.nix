{ pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    "d /media/torrents 0775 qbit users"
  ];

  users.users.qbit = {
    group = "qbit";
    isSystemUser = true;
    createHome = true;
    home = "/var/lib/qbit";
  };

  users.groups.qbit = {
    gid = 10000;
  };

  systemd.services.qbitnox = {
    enable = true;
    after = [ "novpn.service" "network-online.target" ];
    wants = [ "novpn.service" "network-online.target" ];
    bindsTo = [ "novpn.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RuntimeMaxSec = 86400;
      User = "qbit";
      Group = "qbit";
      NetworkNamespacePath = "/run/netns/novpn";
    };
    preStart = "while true; do ip addr show dev novpn1 | grep -q 'inet' && break; sleep 1; done";
    script = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox";
    path = with pkgs; [ iproute2 ];
  };

  systemd.services.novpn.wants = [ "qbitnox.service" ];

  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      friendly_name = "hnw19r";
      media_dir = [
      "V,/media/torrents" #Videos files are located here
      ];
      inotify = "yes";
      log_level = "error";
    };
  };

  systemd.services.minidlna-watch = {
    enable = true;
    description = "Update minidlna cache"; # This is getting annoying. year of the linux desktop they say :)
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5";
    };
    path = with pkgs; [ inotify-tools ];
    script = ''
      #!/bin/sh

      WATCH_DIR="/media/torrents"

      inotifywait -m -r -e modify,create,delete "$WATCH_DIR" |
      while read -r directory event file; do
        echo "$directory$file $event, waiting..."
        sleep 100
        rm -rf /var/cache/minidlna/
        systemctl restart minidlna.service
        echo "cache clear complete" 
      done 
    '';
  };
  
  #services.ttyd.enable = false;
  #services.ttyd.writeable = false;
  # systemd.services.ttyd.script = lib.mkForce ''
  #   ${pkgs.ttyd}/bin/ttyd \
  #     --port 7681 \
  #     --interface lo \
  #     --client-option enableZmodem=true \
  #     --client-option enableSixel=true \
  #     --client-option 'theme={"background": "#171717", "black": "#3F3F3F", "red": "#705050", "green": "#60B48A", "yellow": "#DFAF8F", "blue": "#9AB8D7", "magenta": "#DC8CC3", "cyan": "#8CD0D3", "white": "#DCDCCC", "brightBlack": "#709080", "brightRed": "#DCA3A3", "brightGreen": "#72D5A3", "brightYellow": "#F0DFAF", "brightBlue": "#94BFF3", "brightMagenta": "#EC93D3", "brightCyan": "#93E0E3", "brightWhite": "#FFFFFF"}' \
  #     ${pkgs.shadow}/bin/login
  # '';

  #services.cloudflared.enable = false;
  #services.cloudflared.tunnels = {
  #   "unified" = {
  #     default = "http_status:404";
  #     credentialsFile = "${config.age.secrets.cloudflared.path}";
  #   };
  # };
  
  # systemd.services.cloudflared-tunnel-unified.serviceConfig.Restart = lib.mkForce "on-failure";
  # systemd.services.cloudflared-tunnel-unified.serviceConfig.RestartSec = lib.mkForce 60;
}
