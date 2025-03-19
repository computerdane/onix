{
  olib,
  onix,
  overlays,
}:

{ pkgs, ... }:

{
  nixpkgs.overlays = overlays ++ [ (final: prev: (olib.callAllPackages pkgs onix.packages)) ];
}
