{ lib, inputs, ... }:

{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  environment.persistence = {
    "/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/cloudflare-warp"
        "/var/lib/vnstat"
        "/var/lib/qbit"
        "/var/lib/alsa"
        "/var/lib/cups"
        "/etc/NetworkManager/system-connections"
        "/etc/ssh"
        { directory = "/etc/yggdrasil"; user = "yggdrasil"; group = "yggdrasil"; mode = "0700"; }
        { directory = "/etc/sing-box"; user = "root"; group = "root"; mode = "0770"; }
        { directory = "/etc/wireguard"; user = "wireguard"; group = "wireguard"; mode = "0700"; }
        { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
      ];
      files = [
        "/etc/machine-id"
        { file = "/var/keys/secret_file"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
      ];
    };
    "/virt" = {
      hideMounts = true;
      directories = [
        "/etc/qemu"
        "/var/lib/libvirt"
      ];
    };
  };

  systemd.services.systemd-machine-id-commit.enable = lib.mkForce false;
}