{ pkgs, lib, inputs, stable, unstable, config, ... }:

{
  services.matrix-conduit = {
    enable = true;
    package = inputs.conduwuit.packages.${pkgs.system}.default; 
    settings = {
      global = {
        server_name = inputs.secrets.hosts.twinkcentre.matrix;
        turn_uris = [ inputs.secrets.hosts.twinkcentre.coturn ];
        turn_secret = inputs.secrets.hosts.twinkcentre.coturn_secret;
        proxy = {
          by_domain = [{
            url = "http://localhost:2080";
            include = [ 
              "catgirl.cloud" "*.catgirl.cloud" 
              "matrix.org" "*.matrix.org" 
            ];
            exclude = [];
          }];
        };
      };
    };
  };

  systemd.services.conduit.after = lib.mkForce [ "network-online.target" ];
  systemd.services.conduit.wants = lib.mkForce [ "network-online.target" ];

  # services.matrix-appservice-irc = {
  #   enable = true;
  #   registrationUrl = "http://localhost:8009";
  #   settings = {
  #     homeserver = {
  #       url = "http://localhost:6167";
  #       domain = "localhost:6167";
  #     };
  #     ircService = {
  #       servers = {
  #         "irc.esper.net" = {
  #           name = "espernet";
  #           port = 6697;
  #           ssl = true;
  #           dynamicChannels.enabled = true;
  #           dynamicChannels.aliasTemplate = "#irc_$CHANNEL";
  #           ircClients.nickTemplate = "$DISPLAY";
  #         };
  #       };
  #     };
  #   };
  # };

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
      friendly_name = "twinkcentre";
      media_dir = [
      "V,/media/toshiba/torrents" #Videos files are located here
      ];
      inotify = "yes";
      log_level = "error";
    };
  };

  systemd.services.minidlna-watch = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5";
    };
    path = with pkgs; [ inotify-tools ];
    script = ''
      #!/bin/sh

      WATCH_DIR="/media/toshiba/torrents"

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

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s"; # "1m"

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      } {
        job_name = "zfs";
        static_configs = [{
          targets = [ "localhost:${toString config.services.prometheus.exporters.zfs.port}" ];
        }];
      }
    ];

    exporters.node = {
      enable = true;
      port = 9000;
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
      enabledCollectors = [ "systemd" ];
      # /nix/store/zgsw0yx18v10xa58psanfabmg95nl2bb-node_exporter-1.8.1/bin/node_exporter  --help
      extraFlags = [ "--collector.ethtool" "--collector.softirqs" "--collector.tcpstat" ];
    };
    
    exporters.zfs = {
      enable = true;
      port = 9001;
    };
  };

  services.uptime-kuma.enable = true;

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "${inputs.secrets.hosts.twinkcentre.grafana}";
      };
    };
  };

  systemd.services.grafana-to-ntfy = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = { 
      Restart = "on-failure"; 
      RestartSec = "15"; 
      Type = "simple";
      DynamicUser = "yes";
      EnvironmentFile = "${config.age.secrets.grafana-to-ntfy.path}"; 
      ExecStart = "${inputs.shwewo.packages.${pkgs.system}.grafana-to-ntfy}/bin/grafana-to-ntfy";
    };
  };

  services.forgejo = {
    enable = true;
    database.type = "postgres";
    lfs.enable = true;
    settings = {
      server = {
        DOMAIN = "${inputs.secrets.hosts.twinkcentre.forgejo}";
        ROOT_URL = "https://${inputs.secrets.hosts.twinkcentre.forgejo}/"; 
        HTTP_PORT = 3050;
      };
      service.DISABLE_REGISTRATION = true; 
      services.DISABLE_SSH = true;
      actions = {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "github";
      };
    };
  };

  services.scrutiny = {
    enable = true;
    influxdb.enable = true;
    settings = {
      web = {
        listen.host = "127.0.0.1";
        listen.port = 3100;
      };
      notify = {
        urls = [ "ntfy://ntfy.sh:443/${inputs.secrets.hosts.twinkcentre.ntfy_topic}" ];
      };
    };
    collector = {
      enable = true;
    };
  };

  users.users.compress = {
    group = "compress";
    isSystemUser = true;
    createHome = true;
    home = "/data/compress";
  };

  users.groups.compress = {
    gid = 10050;
  };

  systemd.services.compress = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = { 
      Restart = "on-failure"; 
      RestartSec = "15";
      User = "compress";
      Group = "compress";
      Type = "simple";
      Environment = "PORT=5100 UPLOADS_DIR=/data/compress/uploads FFMPEG_PATH=${pkgs.ffmpeg}/bin/ffmpeg FFPROBE_PATH=${pkgs.ffmpeg}/bin/ffprobe";
      EnvironmentFile = "${config.age.secrets.compress.path}";
      ExecStart = "${inputs.compress.packages.${pkgs.system}.default}/bin/compress";
      PrivateTmp = true;
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
      SystemCallArchitectures = "native";
    };
  };

  services.immich = {
    enable = true;
    mediaLocation = "/data/immich";
  };

  systemd.tmpfiles.rules = [
    "d /data/immich 770 immich immich"
  ];

  # services.guacamole-server = {
  #   enable = true;
  #   package = inputs.nixpkgs2311.legacyPackages.${pkgs.system}.guacamole-server;
  #   userMappingXml = pkgs.writeText "guacamoleusermappingxml" ''
  #     <?xml version="1.0" encoding="UTF-8"?>
  #     <user-mapping>
  #         <authorize
  #             username="guacamole"
  #             password="${inputs.secrets.hosts.twinkcentre.guacamole-password}"
  #             encoding="sha256">

  #           <connection name="win10-ltsc">
  #               <protocol>rdp</protocol>
  #               <param name="hostname">192.168.122.100</param>
  #               <param name="port">3389</param>
  #               <param name="ignore-cert">true</param>
  #               <param name="enable-drive">true</param>
  #               <param name="drive-path">/var/private/guacamole</param>
  #           </connection>
  #         </authorize>
  #     </user-mapping>
  #   '';
  # };

  # services.guacamole-client = {
  #   enable = true;
  #   package = inputs.nixpkgs2311.legacyPackages.${pkgs.system}.guacamole-client;
  #   enableWebserver = true;
  #   settings = {
  #     guacd-port = 4822;
  #     guacd-hostname = "127.0.0.1";
  #   };
  # };
}
