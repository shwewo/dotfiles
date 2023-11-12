let
  cute = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGQ+W/wCNLN4xa4voFIi2mFe/0lnhmxSsH1J4kLrkFtb cute@oracle-cloud";
in {
  "socks.age".publicKeys = [ cute ];
  "reality.age".publicKeys = [ cute ];
  "cloudflared.age".publicKeys = [ cute ];
  "wireguard.age".publicKeys = [ cute ];
  "neko-chromium.age".publicKeys = [ cute ];
  "neko-xfce.age".publicKeys = [ cute ];
}
