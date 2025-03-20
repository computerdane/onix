{ config, pkgs, ... }:

let
  inherit (pkgs) stdenv;
in
{
  home.packages = with pkgs; [
    curl
    wget
  ];

  programs.bat.enable = true;
  programs.fd.enable = true;
  programs.fzf.enable = true;

  home.homeDirectory =
    if stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";

  home.stateVersion = "24.11";
}
