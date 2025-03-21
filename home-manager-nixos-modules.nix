{
  nixpkgs,
  users,
  onix,
  overlaysModule,
  hmModules,
  hmSpecialArgs,
}:

let
  inherit (nixpkgs) lib;
  inherit (lib.attrsets) mapAttrsToList;
in

mapAttrsToList (
  username:
  { hm-configs }:
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
            hmModules
            ;
          hm-config-names = hm-configs;
        };
      };

    home-manager.extraSpecialArgs = hmSpecialArgs;

  }
) users
