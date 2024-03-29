{ pkgs, config, ... }:
  let socksBuilder = attrs: {
    inherit (attrs) name;
    value = {
      enable = true;
      description = "avoid censorship";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = { Restart = "on-failure"; User = "socks"; Group = "socks"; AmbientCapabilities = "CAP_NET_BIND_SERVICE"; };
      script = attrs.script;
      path = with pkgs; [shadowsocks-libev shadowsocks-v2ray-plugin xray ];
    };
  };

  socksed = [
    { name = "socks-v2ray";   script = "ss-server -c ${config.age.secrets.socks.path}"; }
    { name = "socks-reality"; script = "rm -f /tmp/reality.json && ln -s ${config.age.secrets.reality.path} /tmp/reality.json && xray -c /tmp/reality.json"; }
  ];
in {
  users.users.socks = {
    group = "socks";
    isSystemUser = true;
  };  
  users.groups.socks = {};
  systemd.services = builtins.listToAttrs (map socksBuilder socksed);
}