{
  callPackage,
  lib,
  pkgs,

  extraHomeManagerModules,
  extraHomeManagerSpecialArgs,
  files,
  home-manager,
  installHelperScripts,
  olib,
  overlays,
}:

let
  inherit (lib)
    filterAttrs
    flatten
    isDerivation
    listToAttrs
    mapAttrs
    mapAttrsToList
    ;

  allPackages = mapAttrs (name: pkg: callPackage pkg { }) files.packages;

  homeConfigurations = listToAttrs (
    flatten (
      mapAttrsToList (
        hostname:
        {
          users ? { },
          ...
        }:
        (mapAttrsToList (
          username:
          {
            hm-configs ? [ ],
            ...
          }:
          {
            name = "${username}@${hostname}";
            value = olib.assertHomeManagerIsNotNull home-manager (
              home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = import ./home-manager-modules.nix {
                  inherit
                    extraHomeManagerModules
                    files
                    hm-configs
                    installHelperScripts
                    lib
                    overlays
                    username
                    ;
                };
                extraSpecialArgs = extraHomeManagerSpecialArgs;
              }
            );
          }
        ) users)
      ) files.hosts
    )
  );
in
{
  # All custom packages
  legacyPackages = allPackages // {
    inherit homeConfigurations;
  };

  # Custom packages, derivations only
  packages = (filterAttrs (name: pkg: isDerivation pkg) allPackages);
}
