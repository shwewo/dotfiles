{ pkgs, lib, ... }:
let
  socksBuilder = attrs:
    let
      prefixedScript = "default_interface=$(ip route show default | awk '/default/ {print $5}')\n" + attrs.script;
    in
    {
      inherit (attrs) name;
      value = {
        enable = true;
        description = "avoid censorship";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = { Restart = "on-failure"; RestartSec = "15"; User = "socks"; Group = "socks"; };
        script = prefixedScript;
        path = with pkgs; [shadowsocks-libev shadowsocks-v2ray-plugin sing-box wireproxy iproute2 gawk];
      };
    };

  socksed = [
    { name = "socks-v2ray-sweden";   script = "ss-local -c /run/agenix/socks_v2ray_sweden -i $default_interface"; } # port 1080
    { name = "socks-v2ray-canada";   script = "ss-local -c /run/agenix/socks_v2ray_canada -i $default_interface"; } # port 1081
    { name = "socks-v2ray-france";   script = "ss-local -c /run/agenix/socks_v2ray_france -i $default_interface"; } # port 1082
    { name = "socks-v2ray-turkey";   script = "ss-local -c /run/agenix/socks_v2ray_turkey -i $default_interface"; } # port 1083
    { name = "socks-warp";           script = "wireproxy -c /etc/wireguard/warp0.conf"; } # port 3333
    { name = "socks-reality-sweden"; script = ''
      cp -f /run/agenix/socks_reality_sweden /tmp/socks_reality_sweden
      sed -i "s/DEFAULT_INTERFACE/$default_interface/" /tmp/socks_reality_sweden
      sing-box run --config /tmp/socks_reality_sweden
    ''; } # port 2080
  ];
in {
  users.users.socks = {
    group = "socks";
    isSystemUser = true;
  };  
  users.groups.socks = {};
  systemd.services = builtins.listToAttrs (map socksBuilder socksed);
}