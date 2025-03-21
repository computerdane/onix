{
  callPackage,
  home-manager,
  lib,
  pkgs,

  extraHomeManagerModules,
  extraHomeManagerSpecialArgs,
  files,
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

  homeConfigurations = olib.eachSystem (
    listToAttrs (
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
              value = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = import ./home-manager-modules.nix {
                  inherit
                    extraHomeManagerModules
                    files
                    hm-configs
                    lib
                    overlays
                    username
                    ;
                };
                extraSpecialArgs = extraHomeManagerSpecialArgs;
              };
            }
          ) users)
        ) files.hosts
      )
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
