{ inputs, pkgs, lib, unstable, ... }:

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

  # For tun mode, remember setting to networking.firewall.checkReversePath = "loose";

  systemd.services.sing-box-tun = {
    enable = true;
    description = "vpn";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "15";
      Type = "simple";
      ExecStart = "${unstable.sing-box}/bin/sing-box run --config /etc/sing-box/config-tun.json";
    };

    preStart = ''
      ip netns add sb
      ip link add sb-veth0 type veth peer name sb-veth1
      ip link set sb-veth1 netns sb
      ip addr add 10.24.0.1/24 dev sb-veth0
      ip link set sb-veth0 up
      ip netns exec sb ip addr add 10.24.0.2/24 dev sb-veth1
      ip netns exec sb ip link set sb-veth1 up
      ip netns exec sb ip link set lo up
      ip netns exec sb ip route add default via 10.24.0.1
      iptables -t nat -A POSTROUTING -s 10.24.0.0/24 ! -o sb-veth0 -j MASQUERADE
      mkdir -p /etc/netns/sb
      echo "nameserver 10.24.0.1" > /etc/netns/sb/resolv.conf

      cp /etc/resolv.conf /etc/sing-box/resolv.conf
      echo "nameserver 127.0.0.1" > /etc/resolv.conf
    '';

    postStop = ''
      ip link del sb-veth0
      ip netns del sb
      iptables -t nat -D POSTROUTING -s 10.24.0.0/24 ! -o sb-veth0 -j MASQUERADE
      rm /etc/netns/sb/resolv.conf
      rmdir /etc/netns/sb
      rmdir /etc/netns

      cat /etc/sing-box/resolv.conf > /etc/resolv.conf
    '';

    path = with pkgs; [ iptables iproute2 ];
  };

  users.groups.wireguard = {};
  users.users.wireguard = {
    group = "wireguard";
    isSystemUser = true;
  };

  systemd.services.warp = {
    enable = true;
    description = "warp";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStart = "${unstable.amneziawg-tools}/bin/awg-quick up /etc/wireguard/warp0.conf ";
      ExecStop = "${unstable.amneziawg-tools}/bin/awg-quick down /etc/wireguard/warp0.conf";
    };
    
    preStart = "while ! ${pkgs.dig}/bin/nslookup engage.cloudflareclient.com > /dev/null 2>&1; do sleep 5; done"; 
    path = [ unstable.amneziawg-go ];
  };

  systemd.services.warp-proxy = {
    enable = true;
    description = "warp";
    after = [ "network-online.target" "warp.service" ];
    wants = [ "network-online.target" "warp.service" ];
    wantedBy = [ "multi-user.target" "warp.service" ];
    bindsTo = [ "warp.service" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "15";
      Type = "simple";
      ExecStart = "${inputs.shwewo.packages.${pkgs.system}.gogost}/bin/gost -L 'socks5://:2200?interface=warp0&udp=true'";
      DynamicUser = "yes";
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
      ExecStart = "${unstable.yggstack}/bin/yggstack -useconffile /etc/yggdrasil/yggdrasil.conf -socks 127.0.0.1:5050 -local-tcp 127.0.0.1:2500:[324:71e:281a:9ed3::fa11]:1080";
    };
  };
}
