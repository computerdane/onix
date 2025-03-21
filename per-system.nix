{
  callPackage,
  extraHomeManagerModules,
  extraHomeManagerSpecialArgs,
  files,
  home-manager,
  lib,
  olib,
  pkgs,
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
