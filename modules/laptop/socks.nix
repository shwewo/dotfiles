{ stable, inputs, config, pkgs, lib, ... }:
  let socksBuilder = attrs: {
    inherit (attrs) name;
    value = {
      enable = true;
      description = "avoid censorship";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = { Restart = "on-failure"; RestartSec = "15"; User = "socks"; Group = "socks"; };
      script = attrs.script;
      path = with pkgs; [shadowsocks-libev shadowsocks-v2ray-plugin sing-box];
    };
  };

  socksed = [
    { name = "socks-v2ray-sweden";   script = "ss-local -c /run/agenix/socks_v2ray_sweden"; } # port 1080
    { name = "socks-v2ray-canada";   script = "ss-local -c /run/agenix/socks_v2ray_canada"; } # port 1081
    { name = "socks-v2ray-france";   script = "ss-local -c /run/agenix/socks_v2ray_france"; } # port 1082
    { name = "socks-v2ray-turkey";   script = "ss-local -c /run/agenix/socks_v2ray_turkey"; } # port 1083
    { name = "socks-reality-sweden"; script = "sing-box run --config /run/agenix/socks_reality_sweden"; } # port 2080
  ];
in {
  users.users.socks = {
    group = "socks";
    isSystemUser = true;
  };  
  users.groups.socks = {};
  systemd.services = builtins.listToAttrs (map socksBuilder socksed);
}
