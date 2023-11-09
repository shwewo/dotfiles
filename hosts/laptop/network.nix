{ stable, inputs, config, pkgs, lib, ... }:

{  
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;
      server_names = [ "cloudflare" ];
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };

  services.openssh = {
    enable = true;
    listenAddresses = [ { addr = "127.0.0.1"; port = 22; } ];
    settings.PasswordAuthentication = false;
  };

  networking = {
    nameservers = [ "127.0.0.1" "::1" ];
    networkmanager.dns = "none";
    hostName = "laptop";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
    interfaces."wlp1s0".proxyARP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        # qbittorrent
        4780 
        # audiorelay
        59100
      ];
      allowedUDPPorts = [
        # audiorelay
        59100
        59200
      ];
      # allowedTCPPorts = [ 59100 4780 1935 554 ];
      # allowedUDPPorts = [ 61385 59100 59200 64083 554 ];
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ]; # kde connect
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
      checkReversePath = "loose";
    };
  };

  # systemd.services.dnscrypt-watch = {
  #   enable = true;
  #   description = "Monitor DNS state";
  #   after = [ "network-online.target" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Restart = "on-failure";
  #     RestartSec = "5";
  #   };
  #   path = with pkgs; [ dnsutils ];
  #   script = ''
  #     #!/bin/sh
      
  #     while true; do
  #       output=$(nslookup cloudflare.com)

  #       if ! [ $? -eq 0 ]; then
  #         echo "DNS is not working..."
  #         sudo -u cute DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1003/bus notify-send -t 2000 -i computer "Network" "DNS is down, restarting..."
  #       fi

  #       sleep 10
  #     done
  #   '';
  # };
  
  systemd.services.NetworkManager-wait-online.enable = false;
}
