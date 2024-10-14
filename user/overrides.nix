{ pkgs, lib, inputs, stable, unstable, dbpass, USER, ... }:

{
  obs = pkgs.wrapOBS {
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
    ];
  };

  vesktop = pkgs.vesktop.override { electron = pkgs.electron; withSystemVencord = false; };
  lnxrouter = unstable.linux-router.override { useHaveged = true; };
  obsidian = pkgs.obsidian.override { electron = stable.electron; };
  
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
      nohup gtk-launch org.telegram.desktop.desktop  > /dev/null & disown
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

  tor-browser = let
    bin = pkgs.writeScriptBin "tor-browser" ''
      #!/usr/bin/env bash
      ${pkgs.tor-browser}/bin/tor-browser --name tor-browser --class tor-browser $@
    '';
  in pkgs.stdenv.mkDerivation {
    name = "tor-browser";
    nativeBuildInputs = [ pkgs.copyDesktopItems ];
    installPhase = ''
      mkdir -p $out/bin $out/share
      cp ${bin}/bin/tor-browser $out/bin/
      ln -s ${pkgs.tor-browser}/share/icons $out/share/icons
      copyDesktopItems
    '';
    phases = [ "installPhase" ];
    
    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "tor-browser";
        desktopName = "Tor Browser";
        genericName = "Web Browser";
        icon = "tor-browser";
        exec = "tor-browser %U";
        type = "Application";
        categories = [
          "Network"
          "WebBrowser"
          "Security"
        ];
        comment = "Privacy-focused browser routing traffic through the Tor network";
      })
    ];
  };
}