{ inputs, rolling, config, pkgs, ... }:

{
  systemd.services.s-ui-sing-box-watch = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    script = ''
      SIGNAL_FILE="/etc/sing-box/s-ui/signal"
      SERVICE_NAME="s-ui-sing-box.service"

      while true; do
        if [[ -f "$SIGNAL_FILE" ]]; then
          SIGNAL=$(cat "$SIGNAL_FILE")
          case "$SIGNAL" in
            stop)
              systemctl stop "$SERVICE_NAME"
              ;;
            restart)
              systemctl restart "$SERVICE_NAME"
              ;;
          esac
          rm -f "$SIGNAL_FILE"
        fi
        sleep 3
      done
    '';
  };

  systemd.services.s-ui-sing-box = {
    enable = true;
    after = [ "network-online.target" "s-ui-mount-cert.service" ];
    wants = [ "network-online.target" "s-ui-mount-cert.service" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      ENABLE_DEPRECATED_SPECIAL_OUTBOUNDS = "true";
      ENABLE_DEPRECATED_WIREGUARD_OUTBOUND = "true";
    };

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5";
      User = "sing-box";
      Group = "sing-box";
      LimitNOFILE = "infinity";
      ExecStart = "${rolling.sing-box.overrideAttrs (oldAttrs: { tags = oldAttrs.tags ++ [ "with_v2ray_api" ];})}/bin/sing-box run --config /etc/sing-box/s-ui/config.json";
      WorkingDirectory = "/etc/sing-box/s-ui";
      CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH";
      AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH";
    };
  };
  
  fileSystems."/etc/sing-box/s-ui/cert/throwaway_domain_1" = {
    device = "/var/lib/acme/${inputs.secrets.hosts.ampere-24g.throwaway_domain_1}";
    options = [ "bind" "nofail" ];
  };

  security.acme.certs."${inputs.secrets.hosts.ampere-24g.throwaway_domain_1}" = {
    webroot = "/var/lib/acme/acme-challenge/";
    group = "nginx";
  };

  networking.firewall = {
    extraCommands = ''
      iptables  -t nat -A PREROUTING -i enp0s6 -p udp --dport 20000:50000 -j DNAT --to-destination :443
      ip6tables -t nat -A PREROUTING -i enp0s6 -p udp --dport 20000:50000 -j DNAT --to-destination :443
    '';
    extraStopCommands = ''
      iptables  -t nat -D PREROUTING -i enp0s6 -p udp --dport 20000:50000 -j DNAT --to-destination :443
      ip6tables -t nat -D PREROUTING -i enp0s6 -p udp --dport 20000:50000 -j DNAT --to-destination :443
    '';
    interfaces = {
      enp0s6 = {
        allowedTCPPorts = [ 443 ];
        allowedUDPPorts = [
          443 # Hysteria
          22812 # Wireguard 
        ];
        allowedUDPPortRanges = [ { from = 20000; to = 50000; } ];
      };
      enp1s0 = {
        allowedTCPPorts = [ 443 ];
      };
    };
  };

  systemd.services.x-ui-port-forward = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = { 
      Restart = "on-failure"; 
      RestartSec = "15"; 
      Type = "simple";
      DynamicUser = "yes";
      ExecStart = "${pkgs.gost}/bin/gost -L=tcp://10.0.0.12:443/127.0.0.1:443 -L=tcp://10.0.0.120:443/127.0.0.1:443";
      CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
    };
  };

  virtualisation.oci-containers.containers = {
    x-ui = {
      image = "ghcr.io/mhsanaei/3x-ui:latest";
      environment = {
        XRAY_VMESS_AEAD_FORCED = "false";
      };
      volumes = [
        "db:/etc/x-ui/"
        "cert:/etc/x-ui-cert/"
      ];
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--network=host"
      ];
    };
    s-ui = {
      image = "docker.io/alireza7/s-ui:latest";
      volumes = [
        "/etc/sing-box/s-ui:/app/bin"
        "suidb:/usr/local/s-ui/db/"
        "suicert:/root/cert/"
      ];
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--network=host"
      ];
    };
    neko-chromium = {
      image = "ghcr.io/m1k1o/neko/arm-chromium:latest";
      ports = [
        "127.0.0.1:8080:8080"
        "10.0.0.187:52000-52100:52000-52100/udp"
      ];
      environment = {
        NEKO_SCREEN = "1920x1080@30";
        NEKO_EPR = "52000-52100";
        NEKO_ICELITE = "true";
        NEKO_CONTROL_PROTECTION = "true";
      };
      environmentFiles = [
        "${config.age.secrets.neko_chromium.path}"
      ];
    };
  };
}