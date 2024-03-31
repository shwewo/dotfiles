{ pkgs, lib, stdenv, fetchurl, makeWrapper, makeDesktopItem, copyDesktopItems, ... }: 
let
  bin = fetchurl {
    url = "https://raw.githubusercontent.com/shwewo/scripts/main/ephemeralbrowser";
    sha256 = "sha256-RHwXwS+1RHR48eFPx2hn0uNt9mvgFP1AunfEgIK/bRM=";
  };
in stdenv.mkDerivation {
  name = "ephemeralbrowser";
  version = "1.0.0";

  dontUnpack = true;
  dontBuild = true;
  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
  ];

  installPhase = let 
    binPath = lib.makeBinPath (with pkgs; [
      google-chrome
      ungoogled-chromium
      firefox
      gnome.zenity
      libnotify
    ]);
  in ''
    mkdir -p $out/bin/ $out/share
    cp ${bin} $out/bin/.ephemeralbrowser-wrapped
    chmod +x $out/bin/.ephemeralbrowser-wrapped
    makeWrapper $out/bin/.ephemeralbrowser-wrapped $out/bin/ephemeralbrowser --prefix PATH : ${binPath}
    copyDesktopItems
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "ephemeralbrowser";
      desktopName = "Ephemeral Browser";
      icon = "browser";
      exec = "ephemeralbrowser";
      type = "Application";
    })

    (makeDesktopItem {
      name = "captive-browser";
      desktopName = "Captive Portal Browser";
      icon = "nix-snowflake";
      exec = "ephemeralbrowser --captive";
      type = "Application";
    })
  ];
}