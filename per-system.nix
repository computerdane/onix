{
  callPackage,
  files,
  lib,
  system,
}:

let
  inherit (lib) filterAttrs isDerivation mapAttrs;

  allPackages = mapAttrs (name: pkg: callPackage pkg { }) files.packages;
in
{
  # All custom packages
  legacyPackages.${system} = allPackages;

  # Custom packages, derivations only
  packages.${system} = (filterAttrs (name: pkg: isDerivation pkg) allPackages);
}
