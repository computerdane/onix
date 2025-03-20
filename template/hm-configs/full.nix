{ pkgs, ... }:

{
  imports = [ ./minimal.nix ];

  home.packages = with pkgs; [
    aria2
    ffmpeg-full
    unzip
    zip
  ];

  programs.tmux.enable = true;
  programs.yt-dlp.enable = true;
  programs.zoxide.enable = true;

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "Dracula";
      theme_background = false;
      update_ms = 100;
    };
  };
}
