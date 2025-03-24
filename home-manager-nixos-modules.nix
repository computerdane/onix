{
  extraHomeManagerModules,
  extraHomeManagerSpecialArgs,
  files,
  home-manager,
  olib,
  lib,
  overlays,
  users,
}:

let
  inherit (lib) flatten mapAttrsToList;
in

if users != { } then
  olib.assertHomeManagerIsNotNull home-manager (flatten [
    home-manager.nixosModules.home-manager
    (mapAttrsToList (
      username:
      {
        hm-configs ? { },
      }:
      {
        home-manager.users.${username} =
          { ... }:
          {
            imports = import ./home-manager-modules.nix {
              inherit
                extraHomeManagerModules
                files
                hm-configs
                lib
                overlays
                username
                ;
            };
          };
        home-manager.extraSpecialArgs = extraHomeManagerSpecialArgs;
      }
    ) users)
  ])
else
  [ ]
