{ inputs, pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    "d /var/www/ebmcbackups 770 nginx ebmc"
  ];

  services.nginx.enable = true;
  services.nginx.virtualHosts."ebmcbackups" = {
    forceSSL = false;
    listen = [{port = 25751;  addr="127.0.0.1"; ssl=false;}];
    root = "/var/www/ebmcbackups";
    locations."/".extraConfig = ''
      try_files $uri $uri/ =404;
      autoindex on;
    '';
  };

  services.nginx.virtualHosts."http" = {
    forceSSL = false;
    listen = [{port = 80;  addr="0.0.0.0"; ssl=false;}];
    locations."/.well-known/acme-challenge/".extraConfig = ''
      root /var/lib/acme/acme-challenge/;
      try_files $uri $uri/ =404;
      autoindex off;
    '';
  };

  services.nginx.virtualHosts."dummy" = {
    forceSSL = true;
    useACMEHost = "${inputs.secrets.hosts.ampere-24g.throwaway_domain_1}";
    listen = [{port = 443;  addr="10.0.0.187"; ssl=true;}];
  };
}
