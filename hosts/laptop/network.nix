{ stable, inputs, config, pkgs, lib, ... }:

{
  services.openssh = {
    enable = true;
    listenAddresses = [ { addr = "127.0.0.1"; port = 22; } { addr = "100.121.227.118"; port = 22; } ];
    settings.PasswordAuthentication = false;
  };

  services.tailscale.enable = true;
  users.groups.no-net = {};
  networking = {
    nameservers = [ "100.122.26.102" ];
    networkmanager.dns = "none";
    hostName = "laptop";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
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
