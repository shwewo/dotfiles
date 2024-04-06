{ pkgs, lib, inputs, USER, ... }:

{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/tailscale"
      "/var/lib/cloudflare-warp"
      "/var/lib/vnstat"
      "/var/lib/libvirt"
      "/var/lib/qbit"
      "/etc/NetworkManager/system-connections"
      "/etc/qemu"
      { directory = "/var/www"; user = "root"; group = "root"; mode = "u=rwx,g=rwx,o=rwx"; }
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
        ".dropbox"
        ".dropbox-dist"
        ".mozilla"
        ".minecraft"
        ".tlauncher"
        ".vscode"
        ".config/vesktop"
        ".config/Element"
        ".config/Code"
        ".config/obsidian"
        ".config/obs-studio"
        ".config/keepassxc"
        ".config/spotify"
        ".config/gsconnect"
        ".config/monero-project"
        ".config/rclone"
        ".local/share/TelegramDesktop"
        ".local/share/audiorelay"
        ".local/share/org.localsend.localsend_app"
        ".local/share/pano@elhan.io"
        ".local/share/direnv"
        { directory = ".local/share/keyrings"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
        { directory = ".gnupg"; mode = "0700"; }
      ];
    };
  };
}