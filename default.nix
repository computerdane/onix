{
  nixpkgs ? <nixpkgs>,
  pkgs ? import nixpkgs { },
}:

let
  olib = pkgs.callPackage ./olib.nix { };
in

{
  init = pkgs.callPackage ./init.nix { inherit nixpkgs olib; };
}
