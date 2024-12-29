{ pkgs, lib, inputs, unstable, ... }:

{
  networking = {
    hostName = "twinkcentre";
    hostId = "5eaeb42b";
    useDHCP = lib.mkDefault false;
    iproute2.enable = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    
    firewall = {
      enable = true;
      checkReversePath = "loose";
      allowedTCPPorts = [
        # Compress
        5100
        # Qbittorrent 
        50000
        4780
        # win10 rdp
        33880
        # win10-ltsc rdp
        33890
        # win11 rdp
        33895
        # win11-d rdp
        33900
      ];
      allowedUDPPorts = [
        # Qbittorrent 
        50000
      ];
      # interfaces.virbr0.allowedTCPPorts = [ 53 ];
      # interfaces.virbr0.allowedUDPPorts = [ 53 67 ];
      # networking.firewall.interfaces.lxdbr0.allowedUDPPorts = [ 53 67 ];
      # networking.firewall.interfaces.lxdbr0.allowedTCPPorts = [ 53 ];
    };
    
    networkmanager = {
      enable = true;
      dns = "none";
      settings = {
        "connection-dad-default" = {
          "ipv4.dad-timeout" = 0; 
        };
      };
    };

    # nftables = {
    #   enable = true;
    #   ruleset = ''
    #     table inet yggdrasil-fw { 
    #       chain input { 
    #         type filter hook input priority 0; policy accept;
    #         iifname "ygg0" jump ygg-chain 
    #       } 
          
    #       chain ygg-chain { 
    #         ct state established,related accept
    #         icmp type echo-request accept
    #         tcp dport 54921 accept
    #         drop
    #       }
    #     }
    #   '';
    # };
  };

  services.openssh = {
    enable = true;
    ports = [ 54921 ];
    settings.PasswordAuthentication = false;
    settings.X11Forwarding = true;
    extraConfig = ''
      LoginGraceTime 0
    '';
  };
  
  systemd.services.port-forward = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = { 
      Restart = "on-failure"; 
      RestartSec = "15"; 
      Type = "simple";
      DynamicUser = "yes"; 
    };

    script = ''
      ${pkgs.gost}/bin/gost -L=tcp://:33880/192.168.122.50:3389 -L=tcp://:33890/192.168.122.100:3389 -L=tcp://:33895/192.168.122.105:3389 -L=tcp://:33900/192.168.122.110:3389
    '';
  };

  users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9blPuLoJkCfTl88JKpqnSUmybCm7ci5EgWAUvfEmwb" ];

  users.groups.cloudflared = {};
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };

  systemd.services.cloudflared = {
    after = [ "network.target" "network-online.target" ];
    wants = [ "network.target" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${unstable.cloudflared}/bin/cloudflared tunnel --config=${pkgs.writeText "cloudflared.yml" ''{"credentials-file":"/run/agenix/cloudflared","ingress":[{"service":"http_status:404"}],"tunnel":"thinkcentre"}''} --no-autoupdate --post-quantum --compression-quality 3 run thinkcentre";
      DynamicUser = "yes";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  systemd.services.wireproxy-cru = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = { 
      Restart = "on-failure"; 
      RestartSec = "15"; 
      Type = "simple";
      DynamicUser = "yes"; 
      ExecStart = "${pkgs.wireproxy}/bin/wireproxy -c /etc/wireguard/wg0.conf";
    };
  };
  
  users.groups.yggdrasil = {};
  users.users.yggdrasil = {
    group = "yggdrasil";
    isSystemUser = true;
  };

  systemd.services.yggstack = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = { 
      Restart = "on-failure"; 
      RestartSec = "15"; 
      Type = "simple";
      User = "yggdrasil";
      Group = "yggdrasil"; 
      ExecStart = "${unstable.yggstack}/bin/yggstack -useconffile /etc/yggdrasil/yggdrasil.conf -socks 127.0.0.1:5050 -remote-tcp 54921:127.0.0.1:54921";
    };
  };

  # services.yggdrasil = {
  #   enable = true;
  #   persistentKeys = true;
  #   settings = {
  #     Peers = [
  #       "tls://yggpeer.tilde.green:59454"
  #       "tls://de-fsn-1.peer.v4.yggdrasil.chaz6.com:4444"
  #       "tls://23.137.249.65:444"
  #       "tcp://cowboy.supergay.network:9111"
  #       "quic://x-mow-0.sergeysedoy97.ru:65535"
  #       "tcp://x-mow-0.sergeysedoy97.ru:65533"
  #       "quic://srv.itrus.su:7993"
  #       "tls://srv.itrus.su:7992"
  #       # https://github.com/yggdrasil-network/public-peers
  #     ];
  #     IfName = "ygg0";
  #   };
  # };
  
  # systemd.services.yggdrasil.after = [ "nftables.service" ];
  # systemd.services.yggdrasil.wants = [ "nftables.service" ];
  # systemd.services.yggdrasil.bindsTo = [ "nftables.service" ];

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

  systemd.services.lnxrouter-nsd = {
    enable = true;
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "15";
      Type = "exec";
    };

    script = ''
      ${pkgs.iproute2}/bin/ip netns add hotspot_nsd &> /dev/null || true
      
      ${inputs.shwewo.packages.${pkgs.system}.namespaced}/bin/namespaced \
        --name "hotspot" \
        --veth0-ip 10.42.0.3 \
        --veth1-ip 10.42.0.4 \
        --fwmark 0x6e706423 \
        --table 28105 \
        --nokill \
        --dontcreate
    '';

    preStop = ''
      ${pkgs.iproute2}/bin/ip netns exec hotspot_nsd ${pkgs.iw}/bin/iw phy phy0 set netns 1
    '';

    postStart = ''
      while [ ! -e /var/run/netns/hotspot_nsd ]; do sleep 1; done
      ${pkgs.iw}/bin/iw phy phy0 set netns name hotspot_nsd
    '';
  };

  systemd.services.lnxrouter-sing-box = {
    enable = true;
    after = [ "lnxrouter-nsd.service" ];
    wants = [ "lnxrouter-nsd.service" ];
    bindsTo = [ "lnxrouter-nsd.service" ];
    wantedBy = [ "lnxrouter-nsd.service" ];

    serviceConfig = {
      Restart = "on-failure"; 
      RestartSec = "15"; 
      Type = "simple";
      ExecStart = "${pkgs.sing-box}/bin/sing-box run --config /etc/sing-box/config-tun.json";
      NetworkNamespacePath = "/var/run/netns/hotspot_nsd";
    };
  };

  systemd.services.lnxrouter = {
    enable = true;
    after = [ "lnxrouter-sing-box.service" ];
    wants = [ "lnxrouter-sing-box.service" ];
    bindsTo = [ "lnxrouter-sing-box.service" ];
    wantedBy = [ "lnxrouter-sing-box.service" ];

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "15";
      Type = "exec";
      NetworkNamespacePath = "/var/run/netns/hotspot_nsd";
    };

    script = ''
      ${pkgs.util-linux}/bin/rfkill unblock all
      ${pkgs.linux-router}/bin/lnxrouter -g 192.168.10.1 --country RU --ap wlp2s0 twcnt -p ${inputs.secrets.hosts.twinkcentre.network.lnxrouter.wifi_password} --wifi4 --wifi5 --freq-band 5 --no-virt --random-mac --ban-priv
    '';
  };
}
