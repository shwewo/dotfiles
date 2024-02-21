{ stable, inputs, config, pkgs, lib, ... }:

{
  age.secrets = {
    socks_v2ray_sweden = { file = ../../secrets/laptop/socks_v2ray_sweden.age; owner = "socks"; group = "socks"; };
    socks_reality_sweden = { file = ../../secrets/laptop/socks_reality_sweden.age; owner = "socks"; group = "socks"; };
    socks_v2ray_turkey = { file = ../../secrets/laptop/socks_v2ray_turkey.age; owner = "socks"; group = "socks"; };
    socks_v2ray_canada = { file = ../../secrets/laptop/socks_v2ray_canada.age; owner = "socks"; group = "socks"; };
    socks_v2ray_france = { file = ../../secrets/laptop/socks_v2ray_france.age; owner = "socks"; group = "socks"; };
    rclone = { file = ../../secrets/laptop/rclone.age; owner = "cute"; group = "users"; }; 
    backup = { file = ../../secrets/laptop/backup.age; owner = "cute"; group = "users"; }; 
    precise = { file = ../../secrets/laptop/precise.age; owner = "cute"; group = "users"; };
  };

  age.identityPaths = [ "/home/cute/.ssh/id_ed25519" ];
}
