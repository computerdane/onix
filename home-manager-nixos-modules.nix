{
  extraHomeManagerModules,
  extraHomeManagerSpecialArgs,
  files,
  home-manager,
  hostname,
  installHelperScripts,
  olib,
  lib,
  overlays,
  users,
}:

let
  inherit (lib) flatten;
in

if users != { } then
  olib.assertHomeManagerIsNotNull home-manager (flatten [
    home-manager.nixosModules.home-manager
    (map (username: {
      home-manager.users.${username} =
        { ... }:
        {
          imports = import ./home-manager-modules.nix {
            inherit
              extraHomeManagerModules
              files
              installHelperScripts
              lib
              overlays
              username
              ;
          };
        };
      home-manager.extraSpecialArgs = olib.withOnixArg {
        host = hostname;
        user = username;
      } extraHomeManagerSpecialArgs;
    }) users)
  ])
else
  [ ]
