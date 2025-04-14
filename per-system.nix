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
          users ? [ ],
          ...
        }:
        (map (username: {
          name = "${username}@${hostname}";
          value = olib.assertHomeManagerIsNotNull home-manager (
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = import ./home-manager-modules.nix {
                inherit
                  extraHomeManagerModules
                  files
                  installHelperScripts
                  lib
                  overlays
                  username
                  ;
              };
              extraSpecialArgs = olib.withOnixArg {
                host = hostname;
                user = username;
              } extraHomeManagerSpecialArgs;
            }
          );
        }) users)
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
