{
  description = "onix - all your configs in one place";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    {
      init = import ./init.nix { inherit nixpkgs home-manager; };
      templates.default = {
        path = ./template;
        description = "starter template for using onix";
      };
    };
}
