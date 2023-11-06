let
  cute = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPDj9bZ7TRqyiB4PltuHMQ2lqGT8ghfMN1M+nUIfNiqM cute@moldova";
in {
  "socks.age".publicKeys = [ cute ];
  "cloudflared.age".publicKeys = [ cute ];
  "reality.age".publicKeys = [ cute ]; 
}
