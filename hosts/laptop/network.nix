{ stable, inputs, config, pkgs, lib, ... }:

{
  services.openssh = {
    enable = true;
    listenAddresses = [ { addr = "127.0.0.1"; port = 22; } ];
    settings.PasswordAuthentication = false;
  };

  services.tailscale.enable = true;
  users.groups.no-net = {};
  networking = {
    networkmanager = { 
      enable = true;
      wifi.backend = "iwd";
      dns = "none";
    };
    nameservers = [ "100.122.26.102" ];
    hostName = "laptop";
    useDHCP = lib.mkDefault true;
    interfaces.wlan0.proxyARP = true;
    iproute2.enable = true;
    wireless.iwd.enable = true;
    usePredictableInterfaceNames = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        # qbittorrent
        4780 
        # audiorelay
        59100
        # localsend
        53317
      ];
      allowedUDPPorts = [
        # audiorelay
        59100
        59200
        # localsend
        53317
      ];
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ]; # kde connect
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
      checkReversePath = "loose";
      extraCommands = ''
        iptables -A OUTPUT -m owner --gid-owner no-net -j REJECT
      '';
    };
  };
  
  systemd.services.NetworkManager-wait-online.enable = false;
}
