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
  
  systemd.services.NetworkManager-wait-online.enable = false;
  services.tailscale.enable = true;
  services.cloudflared.enable = true;
  services.cloudflared.tunnels = {
    "unified" = {
      default = "http_status:404";
      credentialsFile = "/run/agenix/cloudflared";
    };
  };
  
  systemd.services.cloudflared-tunnel-unified.serviceConfig.Restart = lib.mkForce "on-failure";
  systemd.services.cloudflared-tunnel-unified.serviceConfig.RestartSec = lib.mkForce 60;
}
