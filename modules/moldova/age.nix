{ stable, inputs, config, pkgs, lib, ... }:

{
  age.secrets = {
    cloudflared = { file = ../../secrets/moldova/cloudflared.age; owner = "cloudflared"; group = "cloudflared"; };
    socks = { file = ../../secrets/moldova/socks.age; owner = "socks"; group = "socks"; };
    reality = { file = ../../secrets/moldova/reality.age; owner = "socks"; group = "socks"; };
  };

  age.identityPaths = [ "/home/cute/.ssh/id_ed25519" ];
}
