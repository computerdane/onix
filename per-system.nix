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
        hostname: user-configs:
        (mapAttrsToList (username: user-config: {
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
                  user-config
                  username
                  ;
              };
              extraSpecialArgs = extraHomeManagerSpecialArgs;
            }
          );
        }) user-configs)
      ) files.hm-configs
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
