{ stable, inputs, config, pkgs, lib, ... }:

{
  systemd.tmpfiles.rules = [
    "d /var/www/torrents 0775 qbit users"
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

  # system.activationScripts.iqbit = ''
  #   if [ ! -d "/var/lib/qbit/iqbit" ]; then
  #     ${pkgs.wget}/bin/wget https://github.com/CzBiX/qb-web/releases/download/nightly-20230513/qb-web-nightly-20230513.zip -O /tmp/qb-web.zip
  #     ${pkgs.unzip}/bin/unzip /tmp/qb-web.zip -d /tmp/qb-web
  #     mv /tmp/qb-web/dist/ /var/lib/qbit/qb-web
  #     chown -R qbit:users /var/lib/qbit/qb-web
  #     rm -rf /tmp/qb-web
  #   fi
  # '';

  systemd.services.qbitnox = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 10;
      RuntimeMaxSec=86400;
      User = "qbit";
      Group = "qbit";
    };
    script = ''
      ${pkgs.qbittorrent-nox}/bin/qbittorrent-nox
    '';
  };

  services.tailscale.enable = true;

  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      friendly_name = "Laptop";
      media_dir = [
      "V,/var/www/torrents" #Videos files are located here
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

      WATCH_DIR="/var/www/torrents"

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

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;
      server_names = [ "cloudflare" ];
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };

  # services.ttyd.enable = false;
  # systemd.services.ttyd.script = lib.mkForce ''
  #   ${pkgs.ttyd}/bin/ttyd \
  #     --port 7681 \
  #     --interface lo \
  #     --client-option enableZmodem=true \
  #     --client-option enableSixel=true \
  #     --client-option 'theme={"background": "#171717", "black": "#3F3F3F", "red": "#705050", "green": "#60B48A", "yellow": "#DFAF8F", "blue": "#9AB8D7", "magenta": "#DC8CC3", "cyan": "#8CD0D3", "white": "#DCDCCC", "brightBlack": "#709080", "brightRed": "#DCA3A3", "brightGreen": "#72D5A3", "brightYellow": "#F0DFAF", "brightBlue": "#94BFF3", "brightMagenta": "#EC93D3", "brightCyan": "#93E0E3", "brightWhite": "#FFFFFF"}' \
  #     ${pkgs.shadow}/bin/login
  # '';

  # systemd.services.syncthing = {
  #   enable = false;
  #   description = "syncthing";
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Restart = "always";
  #     RestartSec = "5";
  #     User="cute";
  #   };
  #   path = with pkgs; [ syncthing ];
  #   script = ''syncthing'';
  # };

  # systemd.services.yubinotify = {
  #   enable = true;
  #   description = "yubinotify";
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Restart = "always";
  #     RestartSec = "5";
  #     User="cute";
  #     Type="simple";
  #     Environment="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1003/bus";
  #   };
  #   path = with pkgs; [ gnupg ];
  #   script = ''
  #     #!/bin/sh

  #     ${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector -stdout | while read line; do
  #     if [[ $line == U2F_1* ]]; then
  #       ${pkgs.libnotify}/bin/notify-send "YubiKey" "Waiting for touch..." --icon=fingerprint -t 8000
  #     fi

  #     done
  #   '';
  # };

  # services.cloudflared.enable = false;
  # services.cloudflared.tunnels = {
  #   "unified" = {
  #     default = "http_status:404";
  #     credentialsFile = "/run/agenix/cloudflared";
  #   };
  # };
  
  # systemd.services.cloudflared-tunnel-unified.serviceConfig.Restart = lib.mkForce "on-failure";
  # systemd.services.cloudflared-tunnel-unified.serviceConfig.RestartSec = lib.mkForce 60;
}
