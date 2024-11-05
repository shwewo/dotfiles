{ pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    "d /var/www/internal 550 nginx nginx"
    "d /var/www/private 750 cute nginx"
    "d /var/www/html 774 nginx users"
  ];

  system.activationScripts.nginx_filebrowser = ''
    if [ ! -d "/var/www/filebrowser" ]; then
      ${pkgs.git}/bin/git clone https://github.com/mohamnag/nginx-file-browser /var/www/filebrowser
      chmod -R 555 /var/www/filebrowser
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

  services.nginx.virtualHosts."private" = {
    forceSSL = false;
    listen = [{port = 8085;  addr="127.0.0.1"; ssl=false;}];
    root = "/var/www/private";
    locations."/".extraConfig = ''
      try_files $uri $uri/ =404;
      autoindex off;
    '';
  };

  services.nginx.virtualHosts."internal" = {
    forceSSL = false;
    listen = [{port = 35782;  addr="127.0.0.1"; ssl=false;}];
    root = "/var/www/internal";
    locations."/".extraConfig = ''
      try_files $uri $uri/ =404;
      autoindex on;
    '';
  };
}
