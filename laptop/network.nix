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

  # run this command if you are from russia
  # warp-cli set-custom-endpoint 162.159.193.1:2408
  # also don't forget to connect a vpn before running warp-cli register

  systemd.services.warp-svc = {
    enable = true;
    description = "Cloudflare Zero Trust Client Daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "pre-network.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "15";
      DynamicUser = "no";
      CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
      AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
      StateDirectory = "cloudflare-warp";
      RuntimeDirectory = "cloudflare-warp";
      LogsDirectory = "cloudflare-warp";
      ExecStart = "${pkgs.cloudflare-warp}/bin/warp-svc";
    };
  };

  environment.systemPackages = with pkgs; [
    cloudflare-warp
  ];
  
  systemd.services.NetworkManager-wait-online.enable = false;
}
