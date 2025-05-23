{ inputs, pkgs, lib, rolling, ... }:

{
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking = {
    networkmanager = { 
      enable = true;
      dns = "none";
      wifi.macAddress = "stable";
    };
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    hostName = "laptop";
    hostId = "df3549ee";
    useDHCP = lib.mkDefault true;
    interfaces.wlp1s0.proxyARP = true;
    iproute2.enable = true;
    firewall = {
      enable = true;
      trustedInterfaces = [ "sb0" "sb-veth0" "virbr0" "virbr2" ];
      allowedTCPPorts = [
        # wifi sharing
        53 67
        # audiorelay
        59100
        # localsend
        53317
        # Temp port
        21080
        # qbittorrent
        51150
      ];
      allowedUDPPorts = [
        # wifi sharing
        53 67
        # audiorelay
        59100
        59200
        # localsend 
        53317
        # Temp port
        21080
        # qbittorrent
        51150
      ];
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ]; # kde connect
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
      checkReversePath = "loose";
    };
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    ports = [ 34812 ]; 
  };

  services.cloudflare-warp.enable = true;

  # For tun mode, remember setting to networking.firewall.checkReversePath = "loose";

  users.groups.sing-box = {};
  users.users.sing-box = {
    group = "sing-box";
    isSystemUser = true;
    home = "/etc/sing-box";
  };

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

  #     cp /etc/resolv.conf /etc/sing-box/resolv.conf
  #     echo "nameserver 127.0.0.1" > /etc/resolv.conf
  #   '';

  #   preStop = ''
  #     ip link del sb-veth0
  #     ip netns del sb
  #     iptables -t nat -D POSTROUTING -s 10.24.0.0/24 ! -o sb-veth0 -j MASQUERADE
  #     rm /etc/netns/sb/resolv.conf
  #     rmdir /etc/netns/sb
  #     rmdir /etc/netns

  #     cat /etc/sing-box/resolv.conf > /etc/resolv.conf
  #   '';

  #   path = with pkgs; [ iptables iproute2 iw ];
  # };

  systemd.services.sing-box = {
    enable = true;
    # after = [ "sing-box-pre.service" ];
    # wants = [ "sing-box-pre.service" ];
    # bindsTo = [ "sing-box-pre.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    bindsTo = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      ENABLE_DEPRECATED_GEOIP = "true";
      ENABLE_DEPRECATED_GEOSITE = "true";
    };

    serviceConfig = {
      Restart = "always";
      RestartSec = "15";
      Type = "simple";
      ExecStart = "${rolling.sing-box}/bin/sing-box run --config /etc/sing-box/config-tun.json";
      User = "sing-box";
      Group = "sing-box";
      WorkingDirectory = "/etc/sing-box";
      CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH";
      AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH";
    };
  };

  # systemd.services.warp = {
  #   enable = true;
  #   description = "warp";
  #   after = [ "network-online.target" ];
  #   wants = [ "network-online.target" ];
  #   wantedBy = [ "multi-user.target" ];

  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = "yes";
  #     ExecStart = "${rolling.amneziawg-tools}/bin/awg-quick up /etc/wireguard/warp0.conf ";
  #     ExecStop = "${rolling.amneziawg-tools}/bin/awg-quick down /etc/wireguard/warp0.conf";
  #     CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH";
  #     AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH";
  #   };
    
  #   preStart = "while ! ${pkgs.dig}/bin/nslookup engage.cloudflareclient.com > /dev/null 2>&1; do sleep 5; done"; 
  #   path = [ rolling.amneziawg-go ];
  # };

  users.groups.gogost = {};
  users.users.gogost = {
    group = "gogost";
    uid = 10085;
    isSystemUser = true;
  };

  # systemd.services.warp-proxy = {
  #   enable = true;
  #   description = "warp";
  #   after = [ "network-online.target" "warp.service" ];
  #   wants = [ "network-online.target" "warp.service" ];
  #   wantedBy = [ "multi-user.target" "warp.service" ];
  #   bindsTo = [ "warp.service" ];

  #   serviceConfig = {
  #     Restart = "always";
  #     RestartSec = "15";
  #     Type = "simple";
  #     ExecStart = "${inputs.shwewo.packages.${pkgs.system}.gogost}/bin/gost -L 'socks5://127.0.0.1:2200?interface=warp0&udp=true'";
  #     User = "gogost";
  #     Group = "gogost";
  #   };
  # };

  systemd.services.direct-proxy = {
    enable = true;
    description = "direct";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "15";
      Type = "simple";
      ExecStart = "${inputs.shwewo.packages.${pkgs.system}.gogost}/bin/gost -L 'socks5://127.0.0.1:2600?interface=enp3s0f3u1u1u3,wlp1s0&udp=true'";
      DynamicUser = "yes";
      User = "gogost";
      Group = "gogost";
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
      ExecStart = "${rolling.yggstack}/bin/yggstack -useconffile /etc/yggdrasil/yggdrasil.conf -socks 127.0.0.1:5050 -local-tcp 127.0.0.1:2500:[324:71e:281a:9ed3::fa11]:1080";
    };
  };
}
