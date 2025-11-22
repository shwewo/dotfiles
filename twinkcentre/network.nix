{ pkgs, lib, inputs, rolling, ... }:

{
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking = {
    hostName = "twinkcentre";
    hostId = "5eaeb42b";
    useDHCP = lib.mkDefault false;
    iproute2.enable = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    
    firewall = {
      enable = true;
      checkReversePath = "loose";
      trustedInterfaces = [ "sb0" "sb-veth0" "virbr0" "virbr1" "virbr2" ];
      # allowedTCPPorts = [
      #   # Compress
      #   5100
      #   # Qbittorrent 
      #   50000
      #   4780
      #   # win10 rdp
      #   33880
      #   # win10-ltsc rdp
      #   33890
      #   # win11 rdp
      #   33895
      #   # win11-d rdp
      #   33900
      # ];
      # allowedUDPPorts = [
      #   # Qbittorrent 
      #   50000
      # ];
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

  systemd.services.wireproxy-eu-par1 = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = { 
      Restart = "on-failure"; 
      RestartSec = "15"; 
      Type = "simple";
      ExecStart = "${pkgs.wireproxy}/bin/wireproxy -c /etc/wireguard/eupar1.conf";
    };
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
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --metrics 127.0.0.1:42001 --config=${pkgs.writeText "cloudflared.yml" ''{"credentials-file":"/run/agenix/cloudflared","ingress":[{"service":"http_status:404"}],"tunnel":"thinkcentre"}''} --no-autoupdate --post-quantum --compression-quality 3 run thinkcentre";
      DynamicUser = "yes";
      Restart = "always";
      RestartSec = 10;
    };
  };

  systemd.services.NetworkManager-wait-online.enable = false;
  
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
      ExecStart = "${rolling.yggstack}/bin/yggstack -useconffile /etc/yggdrasil/yggdrasil.conf -socks 127.0.0.1:5050 -remote-tcp 54921:127.0.0.1:54921";
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    extraSetFlags = [
      "--accept-dns=false"
    ];
  };
  # users.groups.sing-box = {};
  # users.users.sing-box = {
  #   group = "sing-box";
  #   isSystemUser = true;
  #   home = "/etc/sing-box";
  # };

  # systemd.services.sing-box-pre = {
  #   after = [ "network-online.target" ];
  #   wants = [ "network-online.target" ];
  #   requires = [ "sing-box.service" ];
  #   wantedBy = [ "multi-user.target" ];

  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = "yes";
  #   };

  #   script = ''
  #     ip netns add sb
  #     ip link add sb-veth0 type veth peer name sb-veth1
  #     ip link set sb-veth1 netns sb
  #     ip addr add 10.24.0.1/24 dev sb-veth0
  #     ip link set sb-veth0 up
  #     ip netns exec sb ip addr add 10.24.0.2/24 dev sb-veth1
  #     ip netns exec sb ip link set sb-veth1 up
  #     ip netns exec sb ip link set lo up
  #     ip netns exec sb ip route add default via 10.24.0.1
  #     iptables -t nat -A POSTROUTING -s 10.24.0.0/24 ! -o sb-veth0 -j MASQUERADE
  #     mkdir -p /etc/netns/sb
  #     echo "nameserver 10.24.0.1" > /etc/netns/sb/resolv.conf

  #     # cp /etc/resolv.conf /etc/sing-box/resolv.conf
  #     # echo "nameserver 127.0.0.1" > /etc/resolv.conf

  #     iw phy phy0 set netns name sb # WIFI ADAPTER MOVING TO MAIN NAMESPACE
  #   '';

  #   preStop = ''
  #     ip netns exec sb iw phy phy0 set netns 1 # WIFI ADAPTER MOVING TO SB NAMESPACE

  #     ip link del sb-veth0
  #     ip netns del sb
  #     iptables -t nat -D POSTROUTING -s 10.24.0.0/24 ! -o sb-veth0 -j MASQUERADE
  #     rm /etc/netns/sb/resolv.conf
  #     rmdir /etc/netns/sb
  #     rmdir /etc/netns

  #     # cat /etc/sing-box/resolv.conf > /etc/resolv.conf
  #   '';

  #   path = with pkgs; [ iptables iproute2 iw ];
  # };

  # systemd.services.sing-box = {
  #   enable = true;
  #   after = [ "sing-box-pre.service" ];
  #   wants = [ "sing-box-pre.service" "lnxrouter.service" ];
  #   bindsTo = [ "sing-box-pre.service" ];
  #   wantedBy = [ "multi-user.target" "sing-box-pre.service" ];

  #   serviceConfig = {
  #     Restart = "always";
  #     RestartSec = "15";
  #     Type = "  simple";
  #     ExecStart = "${rolling.sing-box}/bin/sing-box run --config /etc/sing-box/config-tun.json";
  #     User = "sing-box";
  #     Group = "sing-box";
  #     WorkingDirectory = "/etc/sing-box";
  #     CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH";
  #     AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH";
  #   };
  # };

  # systemd.services.lnxrouter = {
  #   enable = true;
  #   after = [ "network-online.target" ];
  #   wants = [ "network-online.target" ];
  #   wantedBy = [ "multi-user.target" ];

  #   serviceConfig = {
  #     Restart = "on-failure";
  #     RestartSec = "15";
  #     Type = "exec";
  #   };

  #   script = ''
  #     ${pkgs.util-linux}/bin/rfkill unblock all
  #     ${pkgs.linux-router}/bin/lnxrouter -g 192.168.10.1 --country RU --ap wlp2s0 twcnt -p ${inputs.secrets.hosts.twinkcentre.network.lnxrouter.wifi_password} --wifi4 --wifi5 --freq-band 5 --no-virt --random-mac --ban-priv --dns 1.1.1.1
  #   '';
  # };
}
