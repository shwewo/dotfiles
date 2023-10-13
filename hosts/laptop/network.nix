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
      allowedTCPPorts = [ 59100 4780 1935 554 ];
      allowedUDPPorts = [ 61385 59100 59200 64083 554 ];
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
      checkReversePath = "loose";
    };
  };

  systemd.services.dnscrypt-watch = {
    enable = true;
    description = "Monitor DNS state"; 
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5";
    };
    path = with pkgs; [ dnsutils ];
    script = ''
    '';
  };
  
  systemd.services.NetworkManager-wait-online.enable = false;
}
