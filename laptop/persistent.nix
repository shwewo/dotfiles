{ pkgs, lib, inputs, USER, ... }:

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
        "/var/lib/tailscale"
        "/var/lib/cloudflare-warp"
        "/var/lib/vnstat"
        "/var/lib/qbit"
        "/etc/NetworkManager/system-connections"
        { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
      ];
      files = [
        "/etc/machine-id"
        { file = "/var/keys/secret_file"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
      ];
      users.${USER} = {
        directories = [
          "Downloads"
          "Documents"
          "Music"
          "Pictures"
          "Videos"

          "Monero"
          "Dropbox"
          "dev"

          ".google-chrome-russia"
          ".mozilla"
          ".minecraft"
          ".tlauncher"
          ".vscode"
          ".steam"
          ".cache"
          ".java"
          
          ".config/vesktop"
          ".config/Element"
          ".config/Code"
          ".config/obsidian"
          ".config/maestral"
          ".config/obs-studio"
          ".config/keepassxc"
          ".config/spotify"
          ".config/gsconnect"
          ".config/monero-project"
          ".config/rclone"
          ".config/autostart"
          ".config/dconf"
          ".config/gtk-3.0"
          ".local/share/TelegramDesktop"
          ".local/share/org.localsend.localsend_app"
          ".local/share/pano@elhan.io"
          ".local/share/direnv"
          ".local/share/fish"
          ".local/share/z"
          ".local/share/warp"
          ".local/share/Steam"
          ".local/share/maestral"
          ".local/state/wireplumber"
          { directory = ".local/share/keyrings"; mode = "0700"; }
          { directory = ".ssh"; mode = "0700"; }
          { directory = ".gnupg"; mode = "0700"; }
        ];
        files = [
          ".config/mimeapps.list"
          ".config/monitors.xml"
        ];
      };
    };
    "/virt" = {
      hideMounts = true;
      directories = [
        "/etc/qemu"
        "/var/lib/libvirt"
      ];
    };
  };
}