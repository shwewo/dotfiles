{ pkgs, lib, stable, unstable, dbpass, USER, ... }:

{
  obs = pkgs.wrapOBS {
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
    ];
  };

  obsidian = unstable.obsidian.override { electron = stable.electron; };
  lnxrouter = unstable.linux-router.override { useHaveged = true; };
  # I know this is very retarded but this is required for impermanence since dropbox checks for existence of ~/.dropbox-dist, but impermenance mounts it, so it can't be deleted ¯\_(ツ)_/¯
  # dropbox = pkgs.dropbox.override (old: {
  #   buildFHSEnv = a: (old.buildFHSEnv (a // {
  #     runScript = a.runScript.overrideAttrs (oldAttrs: {
  #       buildCommand = oldAttrs.buildCommand + ''
  #         substituteInPlace $out \
  #           --replace \
  #             "if ! [ -d \"\$HOME/.dropbox-dist\" ]; then" \
  #             "if [ ! -d \"\$HOME/.dropbox-dist\" ] || [ ! -f \"\$HOME/.dropbox-dist/VERSION\" ]; then"
  #         substituteInPlace $out \
  #           --replace \
  #             "rm -fr \"\$HOME/.dropbox-dist\"" \
  #             "rm -fr \"\$HOME/.dropbox-dist\" || true"
  #       '';
  #     });
  #   }));
  # });
  # dropbox = pkgs.writeScriptBin "dropbox" "env HOME='$HOME/Documents' ${pkgs.dropbox}/bin/dropbox";
  # dropbox-cli = pkgs.writeScriptBin "dropbox-cli" "${pkgs.dropbox-cli}/bin/dropbox $@";

  vesktop = (unstable.vesktop.override { electron = pkgs.electron; }).overrideAttrs (oldAttrs: {
    desktopItems = [ (pkgs.makeDesktopItem {
      name = "vesktop";
      desktopName = "Discord";
      exec = "vesktop %U";
      icon = "discord";
      startupWMClass = "Vesktop";
      genericName = "Internet Messenger";
      keywords = [ "discord" "vencord" "electron" "chat" ];
      categories = [ "Network" "InstantMessaging" "Chat" ];
    })];
  });

  kitty_wrapped = pkgs.writeScriptBin "kitty_wrapped" ''
    #!/usr/bin/env bash
    pid=$(pgrep "kitty")

    if [[ -z "$pid" ]]; then
      kitty --start-as maximized &
    else
      gdbus call --session --dest org.gnome.Shell --object-path /de/lucaswerkmeister/ActivateWindowByTitle --method de.lucaswerkmeister.ActivateWindowByTitle.activateByWmClass 'kitty'
    fi
  '';

  keepassxc = let
    bin = pkgs.writeScriptBin "keepassxc" ''
      #!/usr/bin/env bash
      QT_QPA_PLATFORM=wayland
      cat ${dbpass} | ${pkgs.keepassxc}/bin/keepassxc --pw-stdin ~/Dropbox/Sync/passwords.kdbx &
      gdbus call --session --dest org.gnome.Shell --object-path /de/lucaswerkmeister/ActivateWindowByTitle --method de.lucaswerkmeister.ActivateWindowByTitle.activateByWmClass 'KeePassXC'
    '';
  in pkgs.stdenv.mkDerivation {
    name = "keepassxc";
    nativeBuildInputs = [ pkgs.copyDesktopItems ];
    installPhase = ''
      mkdir -p $out/bin $out/share
      cp ${bin}/bin/keepassxc $out/bin/
      copyDesktopItems
    '';
    phases = [ "installPhase" ];
    
    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "keepassxc";
        desktopName = "KeePassXC";
        icon = "keepassxc";
        exec = "keepassxc";
        type = "Application";
      })
    ];
  };

  autostart = let
    bin = pkgs.writeScriptBin "autostart" ''
      #!/usr/bin/env bash
      sleep 5
      nohup gtk-launch maestral.desktop > /dev/null & disown
      nohup gtk-launch vesktop.desktop > /dev/null & disown
      nohup gtk-launch org.telegram.desktop.desktop > /dev/null & disown
      nohup gtk-launch spotify.desktop > /dev/null & disown
      nohup gtk-launch firefox.desktop > /dev/null & disown
      nohup gtk-launch keepassxc.desktop > /dev/null & disown
      exit 0
    '';
  in pkgs.stdenv.mkDerivation {
    name = "autostart";
    nativeBuildInputs = [ pkgs.copyDesktopItems ];
    installPhase = ''
      mkdir -p $out/bin $out/share
      cp ${bin}/bin/autostart $out/bin/
      copyDesktopItems
    '';
    phases = [ "installPhase" ];
    
    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "autostart";
        desktopName = "Autostart";
        icon = "app-launcher";
        exec = "autostart";
        type = "Application";
      })
    ];
  };
}