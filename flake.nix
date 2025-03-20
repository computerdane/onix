{
  description = "onix - all your configs in one place";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    {
      init = import ./init.nix { inherit nixpkgs; };
      templates.default = {
        path = ./template;
        description = "starter template for using onix";
      };
    };
}
