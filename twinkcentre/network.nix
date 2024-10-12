{ pkgs, lib, inputs, config, self, USER, stable, unstable, ... }:

{
  networking = {
    hostName = "twinkcentre";
    hostId = "5eaeb42b";
    useDHCP = lib.mkDefault true;
    iproute2.enable = true;
    firewall = {
      enable = true;
      checkReversePath = "loose";
    };
    networkmanager = {
      enable = true;
      settings = {
        "connection-dad-default" = {
          "ipv4.dad-timeout" = 0; 
        }; 
      };
    };
  };

  services.yggdrasil = {
    enable = true;
    persistentKeys = true;
    settings = {
      Peers = [
        "tls://yggpeer.tilde.green:59454"
        "tls://de-fsn-1.peer.v4.yggdrasil.chaz6.com:4444"
        "tls://23.137.249.65:444"
        "tcp://cowboy.supergay.network:9111"
        "quic://x-mow-0.sergeysedoy97.ru:65535"
        "tcp://x-mow-0.sergeysedoy97.ru:65533"
        "quic://srv.itrus.su:7993"
        "tls://srv.itrus.su:7992"
        # https://github.com/yggdrasil-network/public-peers
      ];
    };
  };

  services.openssh = {
    enable = true;
    ports = [ 54921 ];
    settings.PasswordAuthentication = false;
    extraConfig = ''
      LoginGraceTime 0
    '';
  };

  programs.mosh.enable = true;

  services.cloudflared.enable = true;
  services.cloudflared.tunnels = {
    "unified" = {
      default = "http_status:404";
      credentialsFile = "${config.age.secrets.cloudflared.path}";
    };
  };
  
  systemd.services.cloudflared-tunnel-unified.serviceConfig.Restart = lib.mkForce "on-failure";
  systemd.services.cloudflared-tunnel-unified.serviceConfig.RestartSec = lib.mkForce 60;

  systemd.services.NetworkManager-wait-online.enable = false;
}
