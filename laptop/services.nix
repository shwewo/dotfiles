{ pkgs, inputs, unstable, ... }:

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
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Restart = "always";
      RuntimeMaxSec = 86400;
      User = "qbit";
      Group = "qbit";
      PrivateTmp = false;
      PrivateNetwork = false;
      RemoveIPC = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateUsers = true;
      ProtectHome = "yes";
      ProtectProc = "invisible";
      ProcSubset = "pid";
      ProtectSystem = "full";
      ProtectClock = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_NETLINK" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      SystemCallArchitectures = "native";
      CapabilityBoundingSet = "";
      SystemCallFilter = [ "@system-service" ];
    };

    script = "${unstable.qbittorrent-nox}/bin/qbittorrent-nox";
  };

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
