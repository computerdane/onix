{
  extraHomeManagerModules,
  extraHomeManagerSpecialArgs,
  files,
  home-manager,
  hostname,
  installHelperScripts,
  lib,
  olib,
  overlays,
}:

let
  inherit (lib) flatten mapAttrsToList;
in

if builtins.hasAttr hostname files.hm-configs && files.hm-configs.${hostname} != { } then
  olib.assertHomeManagerIsNotNull home-manager (flatten [
    home-manager.nixosModules.home-manager
    (mapAttrsToList (username: user-config: {
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
              user-config
              username
              ;
          };
        };
      home-manager.extraSpecialArgs = extraHomeManagerSpecialArgs;
    }) files.hm-configs.${hostname})
  ])
else
  [ ]
