{ stable, inputs, config, pkgs, lib, ... }:

{
  age.secrets = {
    cloudflared = { file = ../../secrets/oracle-cloud/cloudflared.age; owner = "cloudflared"; group = "cloudflared"; };
    socks = { file = ../../secrets/oracle-cloud/socks.age; owner = "socks"; group = "socks"; };
    reality = { file = ../../secrets/oracle-cloud/reality.age; owner = "socks"; group = "socks"; };
    wireguard = { file = ../../secrets/oracle-cloud/wireguard.age; owner = "root"; group = "root"; };
  };

  age.identityPaths = [ "/home/cute/.ssh/id_ed25519" ];
}
