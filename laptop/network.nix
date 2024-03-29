{ pkgs, lib, ... }:

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
      dns = "none";
    };
    nameservers = [ "100.122.26.102" ];
    hostName = "laptop";
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
      extraCommands = ''
        iptables -A OUTPUT -m owner --gid-owner no-net -j REJECT
      '';
    };
  };

  environment.systemPackages = [
    (pkgs.writeScriptBin "warp-cli" "${pkgs.cloudflare-warp}/bin/warp-cli $@")
  ];

  systemd.services.NetworkManager-wait-online.enable = false;
}
