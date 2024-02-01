{
  spotify,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  xorg,
  pkgs
}: let
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
  spotifywm = stdenv.mkDerivation {
    name = "spotifywm";
    src = fetchFromGitHub {
      owner = "dasj";
      repo = "spotifywm";
      rev = "8624f539549973c124ed18753881045968881745";
      hash = "sha256-AsXqcoqUXUFxTG+G+31lm45gjP6qGohEnUSUtKypew0=";
    };
    buildInputs = [xorg.libX11];
    installPhase = "mv spotifywm.so $out";
  };
in
  spotify.overrideAttrs (
    old: {
      postInstall =
        (old.postInstall or "")
        + ''
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
          sed -i "s:^Name=Spotify.*:Name=Spotify-adblock:" "$out/share/spotify/spotify.desktop"
          wrapProgram $out/bin/spotify \
            --set LD_PRELOAD "${spotify-adblock}/lib/libspotifyadblock.so"
        '';
    }
  )
