{
  extraHomeManagerModules,
  files,
  installHelperScripts,
  lib,
  overlays,
  username,
}:

let
  inherit (lib) attrValues flatten;
in

flatten [
  (
    { lib, pkgs, ... }:
    {
      home.username = username;
      programs.home-manager.enable = true;
      nixpkgs.overlays = attrValues overlays;
      home.packages = lib.mkIf installHelperScripts (pkgs.callPackage ./scripts.nix { });
    }
  )
  (attrValues files.hm-modules)
  files.hm-config
  extraHomeManagerModules
]
