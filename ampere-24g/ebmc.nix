{ inputs, pkgs, lib, ... }:

{
  networking.firewall.interfaces.enp0s6.allowedTCPPorts = [ 38409 ];

  networking.firewall.extraCommands = ''
    iptables -A OUTPUT -p tcp --sport 38409 -m owner --gid-owner 10065 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 38409 -m owner --gid-owner 10065 -j ACCEPT
    iptables -A OUTPUT -p tcp --sport 25589 -m owner --gid-owner 10065 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 25589 -m owner --gid-owner 10065 -j ACCEPT

    ip6tables -A OUTPUT -p tcp --sport 38409 -m owner --gid-owner 10065 -j ACCEPT
    ip6tables -A OUTPUT -p tcp --dport 38409 -m owner --gid-owner 10065 -j ACCEPT
    ip6tables -A OUTPUT -p tcp --sport 25589 -m owner --gid-owner 10065 -j ACCEPT
    ip6tables -A OUTPUT -p tcp --dport 25589 -m owner --gid-owner 10065 -j ACCEPT

    iptables -A OUTPUT -m owner --gid-owner 10065 -j REJECT
    ip6tables -A OUTPUT -m owner --gid-owner 10065 -j REJECT
  '';

  users.groups.ebmc = {
    gid = lib.mkForce 10065;
  };

  users.users.ebmc = {
    isNormalUser = true;
    description = "ebmc minecraft account";
    packages = with pkgs; [ tmux jdk21_headless bash ];
    home = "/home/minecraft/ebmc";
    group = "ebmc";
  };

  systemd.timers."ebmcbackuptimer" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "12h";
      OnUnitActiveSec = "12h";
      Unit = "ebmcbackup.service";
    };
  };

  systemd.services."ebmcbackup" = {
    serviceConfig = {
      Type = "oneshot";
      User = "ebmc";
      IgnoreSIGPIPE = "false";
    };

    script = ''
      /home/minecraft/ebmc/ebmc-backup.sh -v -c -i /home/minecraft/ebmc/server/world/ -o /var/www/ebmcbackups/ -s localhost:25589:${inputs.secrets.hosts.ampere-24g.ebmc-rcon-pass} -w rcon
    '';

    path = with pkgs; [ bash unixtools.xxd gnutar gawk tmux coreutils gzip ];
  };

  systemd.services.instance-eb-mc = {
    enable = true;
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = 10;
      Type = "forking";
      User = "ebmc";
      Group = "ebmc";
      Nice = 5;
      TimeoutStopSec = 90;
      ProtectSystem = "full";
      PrivateDevices = "no";
      NoNewPrivileges = "yes";
      PrivateTmp = "no";
      InaccessiblePaths = "/root /sys /srv";
      ReadWritePaths = "/home/minecraft/ebmc/server";
      WorkingDirectory = "/home/minecraft/ebmc/server";
      PIDFile = "/home/minecraft/ebmc/server/minecraft-server.pid";
      ExecStart = "/home/minecraft/ebmc/server/service.sh start";
      ExecReload = "/home/minecraft/ebmc/server/service.sh reload";
      ExecStop = "/home/minecraft/ebmc/server/service.sh stop";
    };

    path = with pkgs; [ tmux jdk21_headless bash ];
  };
}