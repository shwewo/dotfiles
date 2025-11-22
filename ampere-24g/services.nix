{ inputs, rolling, config, pkgs, ... }:

{
  services.matrix-tuwunel = {
    enable = true;
    package = inputs.tuwunel.packages.${pkgs.system}.default; 
    settings = {
      global = {
        server_name = "matrix.${inputs.secrets.misc.domain}";
        turn_uris = [ "turn:coturn.${inputs.secrets.misc.domain}?transport=udp" ];
        turn_secret = inputs.secrets.misc.coturn_secret;
        # proxy = {
        #   by_domain = [{
        #     url = "http://localhost:2080";
        #     include = [ 
        #       "matrix.org" "*.matrix.org"
        #       "ntfy.sh" "*.ntfy.sh"
        #       "$`œ{inputs.secrets.hosts.twinkcentre.matrix_proxy.clk}" "*.${inputs.secrets.hosts.twinkcentre.matrix_proxy.clk}"
        #     ];
        #     exclude = [];
        #   }];
        # };
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
    wantedBy = [ "multi-user.target" ];
    
    environment = {
      ENABLE_DEPRECATED_SPECIAL_OUTBOUNDS = "true";
      ENABLE_DEPRECATED_WIREGUARD_OUTBOUND = "true";
    };

    serviceConfig = {
      Restart = "always";
      RestartSec = "15";
      Type = "simple";
      ExecStart = "${rolling.sing-box}/bin/sing-box run --config /etc/sing-box/proxy.json";
      User = "sing-box";
      Group = "sing-box";
      WorkingDirectory = "/etc/sing-box";
      CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH";
      AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH";
    };
  };

  users.groups.bots = {};
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
      Group = "bots";
      Type = "simple";
      WorkingDirectory = "/home/bots/musicbot";
      ExecStart = "${pkgs.proxychains-ng}/bin/proxychains4 -f ${pkgs.writeText "proxychains.conf" ''
        [ProxyList]
        socks5 127.0.0.1 2080
      ''} ${pkgs.openjdk}/bin/java -jar musicbot.jar";
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "abuse@cloudflare.com";
  };
}