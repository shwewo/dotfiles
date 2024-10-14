{ pkgs, lib, inputs, config, self, USER, stable, unstable, ... }:

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
        # Qbittorrent 
        50000
        4780
      ];
      allowedUDPPorts = [
        # Qbittorrent 
        50000
      ];
      interfaces.virbr0.allowedTCPPorts = [ 53 ];
      interfaces.virbr0.allowedUDPPorts = [ 53 67 ];
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
  
  systemd.services.yggdrasil.after = [ "nftables.service" ];
  systemd.services.yggdrasil.wants = [ "nftables.service" ];
  systemd.services.yggdrasil.bindsTo = [ "nftables.service" ];
  systemd.services.nftables.wants = [ "yggdrasil.service" ];

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
      RuntimeMaxSec = 86400;
    };

    script = ''
      ${inputs.shwewo.packages.${pkgs.system}.namespaced}/bin/namespaced \
        --name "hotspot" \
        --veth0-ip 10.42.0.3 \
        --veth0-ip 10.42.0.4 \
        --fwmark 0x6e706423 \
        --table 28105 \
        --nokill
    '';

    postStart = ''
      while ! ${pkgs.iproute2}/bin/ip netns list | ${pkgs.gnugrep}/bin/grep -q "hotspot_nsd"; do ${pkgs.coreutils}/bin/sleep 1; done; ${pkgs.iw}/bin/iw phy phy0 set netns name hotspot_nsd
    '';
    preStop = ''
      ${pkgs.iproute2}/bin/ip netns exec hotspot_nsd ${pkgs.iw}/bin/iw phy phy0 set netns 1
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
      DynamicUser = "yes"; 
      ExecStart = "${inputs.shwewo.packages.${pkgs.system}.sing-box}/bin/sing-box run --config /etc/sing-box/config-tun.json";
      NetworkNamespacePath = "/var/run/netns/hotspot_nsd";
      CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
      AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
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
      ${pkgs.linux-router}/bin/lnxrouter -g 192.168.10.1 --country RU --ap wlp2s0 twcnt -p ${inputs.secrets.hosts.twinkcentre.network.lnxrouter.wifi_password} --wifi4 --wifi5 --freq-band 5 --no-virt --random-mac
    '';
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
  systemd.services.cloudflared-tunnel-unified.serviceConfig.RestartSec = lib.mkForce 10;

  systemd.services.NetworkManager-wait-online.enable = false;
}
