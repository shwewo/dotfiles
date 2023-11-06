{ stable, inputs, config, pkgs, lib, ... }:

{
  systemd.tmpfiles.rules = [
    "d /var/www/internal 0660 nginx nginx"
    "d /var/www/html 0774 nginx users"
  ];

  system.activationScripts.nginx_filebrowser = ''
    if [ ! -d "/var/www/filebrowser" ]; then
      ${pkgs.git}/bin/git clone https://github.com/mohamnag/nginx-file-browser /var/www/filebrowser
      chmod 770 /var/www/filebrowser
      chown nginx:nginx /var/www/filebrowser
    fi
  '';

  services.nginx.enable = true;
  services.nginx.virtualHosts."share" = {
    forceSSL = false;
    listen = [{port = 8081;  addr="127.0.0.1"; ssl=false;}];
    root = "/var/www/";
    extraConfig = "index index.html index.htm;";
    locations."/files/".extraConfig = ''
      alias "/var/www/html/";
      try_files $uri $uri/ =404;
      autoindex on;
      index  ___i;
      autoindex_format json;
    '';
    locations."/".extraConfig = ''
      root /var/www/filebrowser;
    '';
  };
}
