{
  description = "onix - all your configs in one place";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      utils,
      ...
    }:
    {
      init = import ./init.nix { inherit nixpkgs utils; };
    };
}
