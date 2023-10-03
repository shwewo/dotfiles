{ stable, inputs, config, pkgs, lib, ... }:

{
  services.nginx.enable = true;
  services.nginx.virtualHosts."laptop" = {
    forceSSL = false;
    listen = [{port = 8081;  addr="127.0.0.1"; ssl=false;}];
    root = "/var/www/";
    extraConfig = "index  index.html index.htm;";
    locations."/files/".extraConfig = ''
      alias "/var/www/html/";
      try_files $uri $uri/ =404;
      autoindex on;
      index  ___i;
      autoindex_format json;
      disable_symlinks off;
    '';
    locations."/".extraConfig = ''
       root /var/www/filebrowser;
    '';
  };

  services.nginx.virtualHosts."internal" = {
    forceSSL = false;
    listen = [{port = 8082;  addr="127.0.0.1"; ssl=false;}];
    locations."/files/".extraConfig = ''
        alias "/var/www/internal/";
        try_files $uri $uri/ =404;
        autoindex on;
    '';
    locations."/".extraConfig = ''
      proxy_redirect off;
      proxy_pass http://localhost:7681;
      proxy_set_header Host $host;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
    '';
    locations."/syncthing/".extraConfig = ''
      proxy_set_header        Host localhost;
      proxy_set_header        Referer  http://localhost:8384;
      proxy_set_header        X-Real-IP $remote_addr;
      proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto $scheme;
      proxy_pass              http://localhost:8384/;
      add_header X-Content-Type-Options "nosniff";
    '';
    locations."/qbittorrent/".extraConfig = ''
      proxy_pass         http://127.0.0.1:4780/;
      proxy_http_version 1.1;
      proxy_set_header   Host               127.0.0.1:4780;
      proxy_set_header   X-Forwarded-Host   $http_host;
      proxy_set_header   X-Forwarded-For    $remote_addr;
    '';
  };
}
