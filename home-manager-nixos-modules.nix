{
  extraHomeManagerModules,
  extraHomeManagerSpecialArgs,
  files,
  home-manager,
  lib,
  users,
}:

let
  inherit (lib) flatten mapAttrsToList;
in

flatten [
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
              username
              ;
          };
        };
      home-manager.extraSpecialArgs = extraHomeManagerSpecialArgs;
    }
  ) users)
]
