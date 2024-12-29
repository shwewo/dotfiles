{ inputs, pkgs, lib, unstable, ... }:

{
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
      trustedInterfaces = [ "ap0" ];
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
      cp /etc/resolv.conf /etc/sing-box/resolv.conf
      echo "nameserver 127.0.0.1" > /etc/resolv.conf
    '';

    postStop = ''
      cat /etc/sing-box/resolv.conf > /etc/resolv.conf
      rm /etc/sing-box/resolv.conf
    '';
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
