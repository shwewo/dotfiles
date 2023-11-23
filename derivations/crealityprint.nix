{ lib, appimageTools }:

appimageTools.wrapType2 { # or wrapType1
  name = "patchwork";
  src = fetchurl {
    url = "https://file2-cdn.creality.com/file/05a4538e0c7222ce547eb8d58ef0251e/Creality_Print-v4.3.7.6627-x86_64-Release.AppImage";
    hash = "sha256-OqTitCeZ6xmWbqYTXp8sDrmVgTNjPZNW0hzUPW++mq4=";
  };
  extraPkgs = pkgs: with pkgs; [ ];
}