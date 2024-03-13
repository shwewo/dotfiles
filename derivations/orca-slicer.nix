{ lib, appimageTools }:

appimageTools.wrapType2 { # or wrapType1
  name = "orcaslicer-appimage-withnet";
  src = builtins.fetchurl {
    url = "https://github.com/SoftFever/OrcaSlicer/releases/download/v2.0.0-beta/OrcaSlicer_Linux_V2.0.0-beta.AppImage";
    sha256 = "2ac1cf1a521485a2a31aff417c0958b3879698531ca9c958be6d97c064676de0";
  };
  extraPkgs = pkgs: with pkgs; [ webkitgtk ];
}
