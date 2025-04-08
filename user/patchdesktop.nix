{ pkgs, lib, inputs, config, self, stable, unstable, rolling, USER, ... }: 

let
  overrides = import ./overrides.nix { inherit inputs pkgs lib config self stable unstable rolling USER; };
  
  patchDesktop = pkg: appName: from: to:
  with pkgs; let
    zipped = lib.zipLists from to;
    # Multiple operations to be performed by sed are specified with -e
    sed-args = builtins.map
      ({ fst, snd }: "-e 's#${fst}#${snd}#g'")
      zipped;
    concat-args = builtins.concatStringsSep " " sed-args;
  in
  lib.hiPrio
    (pkgs.runCommand "${appName}-patched-desktop" { } ''
      ${coreutils}/bin/mkdir -p $out/share/applications
      ${gnused}/bin/sed ${concat-args} \
        ${pkg}/share/applications/${appName}.desktop \
        > $out/share/applications/${appName}.desktop
    '');
in {
  users.users.${USER}.packages = [
    (patchDesktop overrides.vesktop "vesktop" 
      [
        "Name=Vesktop"
        "Icon=vesktop"
      ]
      [
        "Name=Discord"
        "Icon=discord"
      ]
    )

    (patchDesktop rolling.ayugram-desktop "com.ayugram.desktop" 
      [
        "Name=AyuGram Desktop"
        "Icon=ayugram"
      ]
      [
        "Name=Telegram Desktop"
        "Icon=telegram"
      ]
    )
    # (patchDesktop inputs.shwewo.packages.${pkgs.system}.tdesktop "org.telegram.desktop" 
    #   [
    #     "Exec=telegram-desktop -- %u"
    #   ]
    #   [
    #     "Exec=bash -c 'QT_QPA_PLATFORM=xcb telegram-desktop -- %u'"
    #   ]
    # )
  ];
}