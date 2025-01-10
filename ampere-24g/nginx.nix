{ pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    "d /var/www/ebmcbackups 770 nginx nginx"
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
}
