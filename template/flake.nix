{
  description = "a flake based on onix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    onix.url = "github:computerdane/onix/hm-configs-host-user";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      onix,
      ...
    }:
    onix.init {
      inherit nixpkgs home-manager;
      src = ./.;
      installHelperScripts = true;
    };
}
