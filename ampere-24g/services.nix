{ inputs, pkgs, ... }:

{
  services.matrix-conduit = {
    enable = true;
    package = inputs.conduwuit.packages.${pkgs.system}.default; 
    settings = {
      global = {
        server_name = "matrix.${inputs.secrets.misc.domain}";
        turn_uris = [ "turn:coturn.${inputs.secrets.misc.domain}?transport=udp" ];
        turn_secret = inputs.secrets.misc.coturn_secret;
      };
    };
  };
}