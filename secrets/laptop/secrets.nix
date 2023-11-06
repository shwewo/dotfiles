let
  cute = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9blPuLoJkCfTl88JKpqnSUmybCm7ci5EgWAUvfEmwb cute@laptop";
in {
  "socks_v2ray_sweden.age".publicKeys = [ cute ];
  "socks_v2ray_moldova.age".publicKeys = [ cute ];
  "socks_v2ray_turkey.age".publicKeys = [ cute ];
  "socks_v2ray_canada.age".publicKeys = [ cute ];
  "socks_v2ray_france.age".publicKeys = [ cute ];
  "socks_reality_sweden.age".publicKeys = [ cute ];
  "wireguard_sweden.age".publicKeys = [ cute ];
  "cloudflared.age".publicKeys = [ cute ];
  "backup.age".publicKeys = [ cute ]; 
  "rclone.age".publicKeys = [ cute ]; 
  "precise.age".publicKeys = [ cute ];
  ".blogrs.age".publicKeys = [ cute ];
  ".blogrs_webhook.age".publicKeys = [ cute ];
}
