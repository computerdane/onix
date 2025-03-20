{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aria2
    ffmpeg-full
    unzip
    zip
  ];

  programs.tmux.enable = true;
  programs.yt-dlp.enable = true;
  programs.zoxide.enable = true;

  # Use one of our modules
  programs.custom-btop.enable = true;
}
