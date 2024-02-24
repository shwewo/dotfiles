{ fetchurl, lib, stdenv, squashfsTools, xorg, alsa-lib, makeShellWrapper, wrapGAppsHook, openssl, freetype
, glib, pango, cairo, atk, gdk-pixbuf, gtk3, cups, nspr, nss_latest, libpng, libnotify
, libgcrypt, systemd, fontconfig, dbus, expat, ffmpeg_4, curlWithGnuTls, zlib, gnome
, at-spi2-atk, at-spi2-core, libpulseaudio, libdrm, mesa, libxkbcommon
, pname, meta, harfbuzz, libayatana-appindicator, libdbusmenu, libGL, rustPlatform, fetchFromGitHub, fetchgit, pkgs
  # High-DPI support: Spotify's --force-device-scale-factor argument
  # not added if `null`, otherwise, should be a number.
, deviceScaleFactor ? null
}:

let
  # TO UPDATE: just execute the ./update.sh script (won't do anything if there is no update)
  # "rev" decides what is actually being downloaded
  # If an update breaks things, one of those might have valuable info:
  # https://aur.archlinux.org/packages/spotify/
  # https://community.spotify.com/t5/Desktop-Linux
  version = "1.2.31.1205.g4d59ad7c";
  # To get the latest stable revision:
  # curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/spotify?channel=stable' | jq '.download_url,.version,.last_updated'
  # To get general information:
  # curl -H 'Snap-Device-Series: 16' 'https://api.snapcraft.io/v2/snaps/info/spotify' | jq '.'
  # More examples of api usage:
  # https://github.com/canonical-websites/snapcraft.io/blob/master/webapp/publisher/snaps/views.py
  rev = "75";

  deps = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    curlWithGnuTls
    dbus
    expat
    ffmpeg_4 # Requires libavcodec < 59 as of 1.2.9.743.g85d9593d
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    libayatana-appindicator
    libdbusmenu
    libdrm
    libgcrypt
    libGL
    libnotify
    libpng
    libpulseaudio
    libxkbcommon
    mesa
    nss_latest
    pango
    stdenv.cc.cc
    systemd
    xorg.libICE
    xorg.libSM
    xorg.libX11
    xorg.libxcb
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXScrnSaver
    xorg.libxshmfence
    xorg.libXtst
    zlib
  ];

  spotify-adblock = rustPlatform.buildRustPackage {
    pname = "spotify-adblock";
    version = "1.0.3";
    src = fetchFromGitHub {
      owner = "abba23";
      repo = "spotify-adblock";
      rev = "5a3281dee9f889afdeea7263558e7a715dcf5aab";
      hash = "sha256-UzpHAHpQx2MlmBNKm2turjeVmgp5zXKWm3nZbEo0mYE=";
    };
    cargoSha256 = "sha256-wPV+ZY34OMbBrjmhvwjljbwmcUiPdWNHFU3ac7aVbIQ=";

    patchPhase = ''
      substituteInPlace src/lib.rs \
        --replace 'config.toml' $out/etc/spotify-adblock/config.toml
    '';

    buildPhase = ''
      make
     '';

    installPhase = ''
      mkdir -p $out/etc/spotify-adblock
      install -D --mode=644 config.toml $out/etc/spotify-adblock
      mkdir -p $out/lib
      install -D --mode=644 --strip target/release/libspotifyadblock.so $out/lib
      
    '';
  };

  # xstub = stdenv.mkDerivation {
  #   name = "xstub";
  #   src = fetchgit {
  #     url = "https://aur.archlinux.org/spotify-wayland.git";
  #     hash = "sha256-HIYZuRyOO5LUf1qjOBF8fW2SAv+lstqIUOzExEXikeU=";
  #   };
  #   buildInputs = [ pkgs.gcc ];
  #   buildPhase = ''
  #     cc xstub.c -o xstub.so -shared
  #   '';
  #   installPhase = ''
  #     mkdir -p $out/lib/
  #     mv xstub.so $out/lib/
  #   '';
  # };

  # spotifywm = stdenv.mkDerivation {
  #   name = "spotifywm";
  #   src = fetchFromGitHub {
  #     owner = "dasj";
  #     repo = "spotifywm";
  #     rev = "8624f539549973c124ed18753881045968881745";
  #     hash = "sha256-AsXqcoqUXUFxTG+G+31lm45gjP6qGohEnUSUtKypew0=";
  #   };
  #   buildInputs = [xorg.libX11];
  #   installPhase = ''
  #     mkdir -p $out/lib/
  #     mv spotifywm.so $out/lib/
  #   '';
  # };
in

stdenv.mkDerivation {
  inherit pname version;

  # fetch from snapcraft instead of the debian repository most repos fetch from.
  # That is a bit more cumbersome. But the debian repository only keeps the last
  # two versions, while snapcraft should provide versions indefinitely:
  # https://forum.snapcraft.io/t/how-can-a-developer-remove-her-his-app-from-snap-store/512

  # This is the next-best thing, since we're not allowed to re-distribute
  # spotify ourselves:
  # https://community.spotify.com/t5/Desktop-Linux/Redistribute-Spotify-on-Linux-Distributions/td-p/1695334
  src = fetchurl {
    url = "https://api.snapcraft.io/api/v1/snaps/download/pOBIoZ2LrCB3rDohMxoYGnbN14EHOgD7_${rev}.snap";
    hash = "sha256-6434XSxqF5yrNUv/4RddlpUqeYytEeQ0LkUwTQgaDY4=";
  };

  nativeBuildInputs = [ wrapGAppsHook makeShellWrapper squashfsTools ];

  dontStrip = true;
  dontPatchELF = true;

  unpackPhase = ''
    runHook preUnpack
    unsquashfs "$src" '/usr/share/spotify' '/usr/bin/spotify' '/meta/snap.yaml'
    cd squashfs-root
    if ! grep -q 'grade: stable' meta/snap.yaml; then
      # Unfortunately this check is not reliable: At the moment (2018-07-26) the
      # latest version in the "edge" channel is also marked as stable.
      echo "The snap package is marked as unstable:"
      grep 'grade: ' meta/snap.yaml
      echo "You probably chose the wrong revision."
      exit 1
    fi
    if ! grep -q '${version}' meta/snap.yaml; then
      echo "Package version differs from version found in snap metadata:"
      grep 'version: ' meta/snap.yaml
      echo "While the nix package specifies: ${version}."
      echo "You probably chose the wrong revision or forgot to update the nix version."
      exit 1
    fi
    runHook postUnpack
  '';

  # Prevent double wrapping
  dontWrapGApps = true;

  installPhase =
    ''
      runHook preInstall

      libdir=$out/lib/spotify
      mkdir -p $libdir
      mv ./usr/* $out/

      cp meta/snap.yaml $out

      # Work around Spotify referring to a specific minor version of
      # OpenSSL.

      ln -s ${lib.getLib openssl}/lib/libssl.so $libdir/libssl.so.1.0.0
      ln -s ${lib.getLib openssl}/lib/libcrypto.so $libdir/libcrypto.so.1.0.0
      ln -s ${nspr.out}/lib/libnspr4.so $libdir/libnspr4.so
      ln -s ${nspr.out}/lib/libplc4.so $libdir/libplc4.so

      ln -s ${ffmpeg_4.lib}/lib/libavcodec.so* $libdir
      ln -s ${ffmpeg_4.lib}/lib/libavformat.so* $libdir

      rpath="$out/share/spotify:$libdir"

      patchelf \
        --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath $rpath $out/share/spotify/spotify

      librarypath="${lib.makeLibraryPath deps}:$libdir"
      wrapProgramShell $out/share/spotify/spotify \
        ''${gappsWrapperArgs[@]} \
        ${lib.optionalString (deviceScaleFactor != null) ''
          --add-flags "--force-device-scale-factor=${toString deviceScaleFactor}" \
        ''} \
        --prefix LD_LIBRARY_PATH : "$librarypath" \
        --prefix PATH : "${gnome.zenity}/bin" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--enable-features=UseOzonePlatform --ozone-platform=wayland}}"

      # fix Icon line in the desktop file (#48062)
      sed -i "s:^Icon=.*:Icon=spotify-client:" "$out/share/spotify/spotify.desktop"

      # Desktop file
      mkdir -p "$out/share/applications/"
      cp "$out/share/spotify/spotify.desktop" "$out/share/applications/"

      # Icons
      for i in 16 22 24 32 48 64 128 256 512; do
        ixi="$i"x"$i"
        mkdir -p "$out/share/icons/hicolor/$ixi/apps"
        ln -s "$out/share/spotify/icons/spotify-linux-$i.png" \
          "$out/share/icons/hicolor/$ixi/apps/spotify-client.png"
      done

      runHook postInstall

      # Patching the shit out of this
 
      mkdir spotify-xpui
      mv $out/share/spotify/Apps/xpui.spa .
      ${pkgs.unzip}/bin/unzip -qq xpui.spa -d spotify-xpui/
      
      cd spotify-xpui/
      ${pkgs.perl}/bin/perl -pi -w -e 's|adsEnabled:!0|adsEnabled:!1|' xpui.js
      ${pkgs.perl}/bin/perl -pi -w -e 's|allSponsorships||' xpui.js
      ${pkgs.perl}/bin/perl -pi -w -e 's/(return|.=.=>)"free"===(.+?)(return|.=.=>)"premium"===/$1"premium"===$2$3"free"===/g' xpui.js
      ${pkgs.perl}/bin/perl -pi -w -e 's/(case .:|async enable\(.\)\{)(this.enabled=.+?\(.{1,3},"audio"\),|return this.enabled=...+?\(.{1,3},"audio"\))((;case 4:)?this.subscription=this.audioApi).+?this.onAdMessage\)/$1$3.cosmosConnector.increaseStreamTime(-100000000000)/' xpui.js
      ${pkgs.perl}/bin/perl -pi -w -e 's|(Enables quicksilver in-app messaging modal",default:)(!0)|$1false|' xpui.js
      ${pkgs.perl}/bin/perl -pi -w -e 's/(\.WiPggcPDzbwGxoxwLWFf\s*{)/$1 height: 0;/;' home-hpto.css

      ${pkgs.zip}/bin/zip -qq -r xpui.spa .
      mv xpui.spa $out/share/spotify/Apps/xpui.spa
      cd ..
      rm xpui.spa

      ln -s ${spotify-adblock}/lib/libspotifyadblock.so $libdir
      wrapProgram $out/bin/spotify \
        --set LD_PRELOAD "${spotify-adblock}/lib/libspotifyadblock.so"
      sed -i 's/Exec=spotify %U/Exec=spotify --uri=%U/g' "$out/share/applications/spotify.desktop"
    '';

  meta = meta // {
    maintainers = with lib.maintainers; [ eelco ftrvxmtrx sheenobu timokau ma27 ];
  };
}
