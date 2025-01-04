{ pkgs, lib, inputs, unstable, config, ... }:

{
  services.matrix-conduit = {
    enable = false;
    package = inputs.conduwuit.packages.${pkgs.system}.default; 
    settings = {
      global = {
        server_name = "matrix.${inputs.secrets.misc.domain}";
        turn_uris = [ "turn:coturn.${inputs.secrets.misc.domain}?transport=udp" ];
        turn_secret = inputs.secrets.misc.coturn_secret;
        proxy = {
          by_domain = [{
            url = "http://localhost:2081";
            include = [ 
              "catgirl.cloud" "*.catgirl.cloud" 
              "matrix.org" "*.matrix.org"
              "ntfy.sh" "*.ntfy.sh"
              "${inputs.secrets.hosts.twinkcentre.matrix_proxy.clk}" "*.${inputs.secrets.hosts.twinkcentre.matrix_proxy.clk}"
            ];
            exclude = [];
          }];
        };
      };
    };
  };

  systemd.services.conduit.after = lib.mkForce [ "network-online.target" ];
  systemd.services.conduit.wants = lib.mkForce [ "network-online.target" ];

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
        domain = "grafana.${inputs.secrets.misc.domain}";
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
        DOMAIN = "forgejo.${inputs.secrets.misc.domain}";
        ROOT_URL = "https://forgejo.${inputs.secrets.misc.domain}/"; 
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

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances = {
      default = {
        enable = true;
        tokenFile = config.age.secrets.gitea-runner.path;
        url = "https://forgejo.${inputs.secrets.misc.domain}/";
        name = "local";
        hostPackages = with pkgs; [
          bash
          coreutils
          curl
          gawk
          gitMinimal
          gnused
          nodejs
          wget
          sudo
          nix
        ];
        labels = [
          "ubuntu-latest:docker://catthehacker/ubuntu:act-latest"
          "ubuntu-22.04:docker://catthehacker/ubuntu:act-22.04"
          "ubuntu-20.04:docker://catthehacker/ubuntu:act-20.04"
          "ubuntu-18.04:docker://catthehacker/ubuntu:act-20.04"
        ];
        settings = {
          container = {
            options = "--device /dev/kvm --add-host=twinkcentre:127.0.0.1";
            network = "host";
          };
        };
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

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud30;
    hostName = "nextcloud.${inputs.secrets.misc.domain}";
    configureRedis = true;
    config.adminpassFile = "${config.age.secrets.nextcloud-admin.path}";
    extraAppsEnable = true;
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) contacts calendar tasks notes;
    };
    settings = {
      overwriteprotocol = "https";
    };
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      listen-http = ":8999";
      base-url = "https://ntfy.${inputs.secrets.misc.domain}";
    };
  };

  # services.plex = {
  #   enable = true;
  #   openFirewall = true;
  #   dataDir = "/data/plex";
  # };

  # services.murmur = {
  #   enable = true;
  #   openFirewall = true;
  # };

  # systemd.services.murmur.wantedBy = lib.mkForce [];

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
