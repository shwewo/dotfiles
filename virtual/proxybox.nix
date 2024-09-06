{ pkgs, lib, config, inputs, ... }:

{
  system.stateVersion = config.system.nixos.version;
  networking.hostName = "proxybox";
  users.users.root.password = "proxybox";

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    hostKeys = [ 
      { path = "/persist/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; }
      { path = "/persist/etc/ssh/ssh_host_rsa_key"; type = "rsa"; bits = 4096; }
    ];
  };

  fileSystems."/persist".neededForBoot = lib.mkForce true;

  environment.persistence = {
    "/persist" = {
      hideMounts = true;
      directories = [
        "/var/lib/cloudflare-warp"
      ];
    };
  };

  systemd.services.warp-svc = {
    enable = true;
    description = "Cloudflare Zero Trust Client Daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "pre-network.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "15";
      DynamicUser = "no";
      CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
      AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
      StateDirectory = "cloudflare-warp";
      RuntimeDirectory = "cloudflare-warp";
      LogsDirectory = "cloudflare-warp";
      ExecStart = "${pkgs.cloudflare-warp}/bin/warp-svc";
      LogLevelMax = 3;
      CPUQuota = [ "10%" ];
    };
  };

  services.tor = {
    enable = true;
    client = {
      enable = true;
      socksListenAddress = 9999;
    };
    settings = {
      Socks5Proxy = "localhost:8888";
      ControlPort = 9051;
      CookieAuthentication = true;
    };
  };

  systemd.services.tor.serviceConfig.CPUQuota = [ "10%" ];

  systemd.services.gost = {
    enable = true;
    description = "gost";
    wantedBy = [ "multi-user.target" ];
    after = [ "pre-network.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "15";
      DynamicUser = "yes";
      ExecStart = "${pkgs.gost}/bin/gost -L tcp://:3050/localhost:8888 -L tcp://:9050/localhost:9999";
    };  
  };

  environment.systemPackages = with pkgs; [
    cloudflare-warp
    (pkgs.writeScriptBin "nyx" ''sudo -u tor -g tor ${inputs.nixpkgs2105.legacyPackages."${pkgs.system}".nyx}/bin/nyx $@'')
  ];

  networking.firewall.enable = false;

  microvm = {
    mem = 384;
    hypervisor = "qemu";
    vcpu = 1;

    forwardPorts = [
      { from = "host"; host.port = 8022; guest.port = 22; }
      { from = "host"; host.port = 3050; guest.port = 3050; }
      { from = "host"; host.port = 9050; guest.port = 9050; }
    ];
    
    interfaces = [
      { type = "user"; id = "usernet"; mac = "00:00:00:00:00:01"; }
    ];

    shares = [ {
      proto = "9p";
      tag = "ro-store";
      source = "/nix/store";
      mountPoint = "/nix/.ro-store";
    } {
      proto = "9p";
      tag = "persist";
      source = "/virt/microvm/proxybox/persist";
      mountPoint = "/persist";
    }];
  };
}