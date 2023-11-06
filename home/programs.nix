{ inputs, home, config, lib, pkgs, specialArgs, ... }: 

{
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      matklad.rust-analyzer
      bbenoist.nix
    ];
  };
  
  programs.git = {
    enable = true;
    userName  = "shwewo";
    userEmail = "shwewo@gmail.com";
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "oracle-cloud" = {
        hostname = inputs.meow.hosts.oracle-cloud.network.ip;
        port = inputs.meow.hosts.oracle-cloud.network.ssh.port;
      };
      "moldova" = {
        hostname = inputs.meow.hosts.moldova.network.ip;
      };
      "canada" = {
        hostname = inputs.meow.hosts.canada.network.ip;
        port = inputs.meow.hosts.canada.network.ssh.port;
      };
      "finland" = {
        hostname = inputs.meow.hosts.finland.network.ip;
        port = inputs.meow.hosts.finland.network.ssh.port;
      };
      "france" = {
        hostname = inputs.meow.hosts.france.network.ip;
        port = inputs.meow.hosts.france.network.ssh.port;
      };
    };
  };

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
    ];
  };

  programs.fish = {
    enable = true;
    
    shellAliases = {
      r = "sudo nixos-rebuild switch --flake ~/dev/dotfiles/";
      sign = "~/.local/share/sign";
      mc = "steam-run java -jar ~/Dropbox/Software/minecraft.jar";
      run = "~/.local/share/run";
      fru = "trans ru:en";
      fen = "trans en:ru";
    };
    shellInit = ''
        set fish_cursor_normal block
        set fish_greeting
        any-nix-shell fish --info-right | source
    '';
  };

  programs.kitty = {
    enable = true;
    shellIntegration.enableFishIntegration = false;
    settings = {
      background = "#171717";
      foreground = "#DCDCCC";
      background_opacity = "0.8";
      remember_window_size = "yes";
     
      color0 = "#3F3F3F";
      color1 = "#705050";
      color2 = "#60B48A";
      color3 = "#DFAF8F";
      color4 = "#9AB8D7";
      color5 = "#DC8CC3";
      color6 = "#8CD0D3";
      color7 = "#DCDCCC";

      color8 = "#709080";
      color9 = "#DCA3A3";
      color10 = "#72D5A3";
      color11 = "#F0DFAF";
      color12 = "#94BFF3";
      color13 = "#EC93D3";
      color14 = "#93E0E3";
      color15 = "#FFFFFF";
    };
  };

  programs.mpv = { 
    enable = true;
    config = {
      hwdec = "auto";
      slang = "en,eng";
      alang = "en,eng";
      subs-fallback = "default";
      subs-with-matching-audio = "yes";
      save-position-on-quit = "yes";
    };
    scripts = with pkgs; [ 
      mpvScripts.autoload
    ];
    scriptOpts = {
      autoload = {
        disabled = "no";
        images = "no";
        videos = "yes";
        audio = "yes";
        additional_image_exts = "list,of,ext";
        additional_video_exts = "list,of,ext";
        additional_audio_exts = "list,of,ext";
        ignore_hidden = "yes";
      };
     };
  };
}