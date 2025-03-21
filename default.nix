{
  nixpkgs,
}:

let
  olib = import ./olib.nix { lib = nixpkgs.lib; };
in

{
  init = import ./init.nix { inherit nixpkgs olib; };
}
