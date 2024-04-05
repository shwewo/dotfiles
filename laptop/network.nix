{ pkgs, lib, inputs, config, self, unstable, ... }:

{
  imports = [
    "${self}/generics/gateway.nix"
    (import "${self}/generics/proxy.nix" { 
      inherit pkgs lib inputs unstable;
      socksed = [
        { name = "socks-v2ray-sweden";      script = "ss-local -c           ${config.age.secrets.socks_v2ray_sweden.path}";    } # port 1080
        { name = "socks-v2ray-canada";      script = "ss-local -c           ${config.age.secrets.socks_v2ray_canada.path}";    } # port 1081
        { name = "socks-v2ray-france";      script = "ss-local -c           ${config.age.secrets.socks_v2ray_france.path}";    } # port 1082
        { name = "socks-v2ray-turkey";      script = "ss-local -c           ${config.age.secrets.socks_v2ray_turkey.path}";    } # port 1083
        { name = "socks-reality-sweden";    script = "sing-box run --config ${config.age.secrets.socks_reality_sweden.path}";  } # port 2080
        { name = "socks-reality-austria";   script = "sing-box run --config ${config.age.secrets.socks_reality_austria.path}"; } # port 2081
        { name = "socks-warp";              script = "wireproxy -c /etc/wireguard/warp0.conf";                                 } # port 3333
        { name = "socks-novpn";             script = "gost -L socks5://192.168.150.2:3535";                                    } # port 3535
      ];
    })
  ];

  services.openssh = {
    enable = true;
    listenAddresses = [ { addr = "127.0.0.1"; port = 22; } ];
    settings.PasswordAuthentication = false;
  };

  services.tailscale.enable = true;
  networking = {
    networkmanager = { 
      enable = true;
      dns = "none";
      wifi.macAddress = "stable";
    };
    nameservers = [ "100.122.26.102" ];
    hostName = "laptop";
    hostid = "e56b176f";
    useDHCP = lib.mkDefault true;
    interfaces.wlp1s0.proxyARP = true;
    iproute2.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        # qbittorrent
        4780 
        # audiorelay
        59100
        # localsend
        53317
        # dropbox
        17500
      ];
      allowedUDPPorts = [
        # audiorelay
        59100
        59200
        # localsend 
        53317
        # dropbox
        17500
      ];
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ]; # kde connect
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
      checkReversePath = "loose";
    };
  };
  
  systemd.services.NetworkManager-wait-online.enable = false;
}
