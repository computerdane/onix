{
  nixpkgs ? <nixpkgs>,
  system ? null,
  pkgs ? import nixpkgs { inherit system; },
}:

let
  olib = pkgs.callPackage ./olib.nix { };
in

{
  init = pkgs.callPackage ./init.nix { inherit nixpkgs olib; };
}
