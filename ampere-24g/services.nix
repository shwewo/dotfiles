{ inputs, unstable, config, pkgs, ... }:

{
  services.matrix-conduit = {
    enable = true;
    package = inputs.conduwuit.packages.${pkgs.system}.default; 
    settings = {
      global = {
        server_name = "matrix.${inputs.secrets.misc.domain}";
        turn_uris = [ "turn:coturn.${inputs.secrets.misc.domain}?transport=udp" ];
        turn_secret = inputs.secrets.misc.coturn_secret;
      };
    };
  };

  users.groups.sing-box = {};
  users.users.sing-box = {
    group = "sing-box";
    isSystemUser = true;
    home = "/etc/sing-box";
  };

  systemd.services.sing-box = {
    enable = true;
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    bindsTo = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "15";
      Type = "simple";
      ExecStart = "${unstable.sing-box}/bin/sing-box run --config /etc/sing-box/proxy.json";
      User = "sing-box";
      Group = "sing-box";
      WorkingDirectory = "/etc/sing-box";
      CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH";
      AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH";
    };
  };

  users.users.bots = {
    isNormalUser = true;
    description = "bots account";
  };

  systemd.services.musicbot = {
    enable = true;
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "30";
      User = "bots";
      Group = "users";
      Type = "simple";
      WorkingDirectory = "/home/bots/musicbot";
      ExecStart = "${pkgs.proxychains-ng}/bin/proxychains4 -f ${pkgs.writeText "proxychains.conf" ''
        [ProxyList]
        socks5 127.0.0.1 2080
      ''} ${pkgs.openjdk}/bin/java -jar musicbot.jar";
    };
  };

  # services.nginx = {
  #   enable = true;
  #   virtualHosts."whoasked" = {
  #     listen = [{port = 8080; addr="0.0.0.0"; ssl=true; }];
  #     enableACME = true;
  #     forceSSL = true;
  #     root = "/var/www/whoasked";
  #   };
  # };
  
  # security.acme.defaults.email = "abuse@cloudflare.com";
  # security.acme.acceptTerms = true;

  # system.activationScripts.create-s-ui-pod = ''
  #   ${pkgs.podman}/bin/podman pod exists s-ui || ${pkgs.podman}/bin/podman pod create -n s-ui -p '127.0.0.1:2095:2095' -p '127.0.0.1:2096:2096'
  # '';

  virtualisation.oci-containers.containers = {
    # marzban = {
    #   image = "gozargah/marzban:latest";
    #   ports = [
    #     "10.0.0.12:443:443"
    #     "10.0.0.120:443:443"
    #   ];
    #   volumes = [
    #     "marzban:/var/lib/marzban"
    #     "/tmp/.marzban-uds:/uds"
    #   ];
    #   environment = {
    #     UVICORN_UDS = "/uds/marzban.socket";
    #     SUDO_USERNAME = "";
    #     SUDO_PASSWORD = "";
    #   };
    # };
    x-ui = {
      image = "ghcr.io/mhsanaei/3x-ui:latest";
      ports = [
        "8443:8443"
        "127.0.0.1:2053:2053"
        "127.0.0.1:2054:2054"
        "10.0.0.12:443:443"
        "10.0.0.120:443:443"
      ];
      environment = {
        XRAY_VMESS_AEAD_FORCED = "false";
      };
      volumes = [
        "db:/etc/x-ui/"
        "cert:/etc/x-ui-cert/"
      ];
    };
    s-ui = {
      ports = [
        "127.0.0.1:2095:2095"
        "127.0.0.1:2096:2096"
      ];
      image = "docker.io/alireza7/s-ui:latest";
      volumes = [
        "suidb:/usr/local/s-ui/db/"
        "suicert:/root/cert/"
      ];
    };
    # s-ui-singbox = {
    #   image = "docker.io/alireza7/s-ui-singbox:latest";
    #   volumes = [
    #     "singbox:/app/"
    #     "suicert:/cert"
    #   ];
    #   extraOptions = [ "--pod=s-ui" ];
    # };
    neko-chromium = {
      image = "ghcr.io/m1k1o/neko/arm-chromium:latest";
      ports = [
        "127.0.0.1:8080:8080"
        "10.0.0.187:52000-52100:52000-52100/udp"
      ];
      environment = {
        NEKO_SCREEN = "1920x1080@30";
        NEKO_EPR = "52000-52100";
        NEKO_ICELITE = "true";
        NEKO_CONTROL_PROTECTION = "true";
      };
      environmentFiles = [
        "${config.age.secrets.neko_chromium.path}"
      ];
    };
  };
}