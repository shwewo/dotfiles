{ pkgs, rolling, ... }:

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

    script = "${rolling.qbittorrent-nox}/bin/qbittorrent-nox";
  };

  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      friendly_name = "hnw19r";
      media_dir = [
      "V,/media/torrents" #Videos files are located here
      ];
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
}
