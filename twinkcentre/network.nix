{ pkgs, lib, inputs, config, self, USER, stable, unstable, ... }:

{
  networking = {
    hostName = "twinkcentre";
    hostId = "5eaeb42b";
    useDHCP = lib.mkDefault true;
    iproute2.enable = true;
    
    firewall = {
      enable = true;
      checkReversePath = "loose";
    };
    
    networkmanager = {
      enable = true;
      settings = {
        "connection-dad-default" = {
          "ipv4.dad-timeout" = 0; 
        }; 
      };
    };

    nftables = {
      enable = true;
      ruleset = ''
        table inet yggdrasil-fw { 
          chain input { 
            type filter hook input priority 0; policy accept;
            iifname "ygg0" jump ygg-chain 
          } 
          
          chain ygg-chain { 
            ct state established,related accept
            icmp type echo-request accept
            tcp dport 54921 accept
            drop
          }
        }
      '';
    };
  };

  services.yggdrasil = {
    enable = true;
    persistentKeys = true;
    settings = {
      Peers = [
        "tls://yggpeer.tilde.green:59454"
        "tls://de-fsn-1.peer.v4.yggdrasil.chaz6.com:4444"
        "tls://23.137.249.65:444"
        "tcp://cowboy.supergay.network:9111"
        "quic://x-mow-0.sergeysedoy97.ru:65535"
        "tcp://x-mow-0.sergeysedoy97.ru:65533"
        "quic://srv.itrus.su:7993"
        "tls://srv.itrus.su:7992"
        # https://github.com/yggdrasil-network/public-peers
      ];
      IfName = "ygg0";
    };
  };

  systemd.services.sing-box = {
    enable = true;
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = { 
      Restart = "on-failure"; 
      RestartSec = "15"; 
      Type = "simple";
      DynamicUser = "yes"; 
      RuntimeMaxSec=3600;
      ExecStart = "${pkgs.sing-box}/bin/sing-box run --config /etc/sing-box/config.json";
    };
  };

  services.openssh = {
    enable = true;
    ports = [ 54921 ];
    settings.PasswordAuthentication = false;
    extraConfig = ''
      LoginGraceTime 0
    '';
  };

  programs.mosh.enable = true;

  services.cloudflared.enable = true;
  services.cloudflared.tunnels = {
    "unified" = {
      default = "http_status:404";
      credentialsFile = "${config.age.secrets.cloudflared.path}";
    };
  };
  
  systemd.services.cloudflared-tunnel-unified.serviceConfig.Restart = lib.mkForce "on-failure";
  systemd.services.cloudflared-tunnel-unified.serviceConfig.RestartSec = lib.mkForce 60;

  systemd.services.NetworkManager-wait-online.enable = false;
}
