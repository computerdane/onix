{
  nixpkgs,
  users,
  onix,
  overlaysModule,
  homeModules,
  homeSpecialArgs,
}:

let
  inherit (nixpkgs) lib;
  inherit (lib.attrsets) mapAttrsToList;
in

mapAttrsToList (
  username:
  { home-config }:
  {

    home-manager.users.${username} =
      { ... }:
      {
        imports = import ./home-manager-modules.nix {
          inherit
            nixpkgs
            username
            onix
            overlaysModule
            homeModules
            ;
          home-config-name = home-config;
        };
      };

    home-manager.extraSpecialArgs = homeSpecialArgs;
  }
) users
