{
  callPackage,
  files,
  lib,
}:

let
  inherit (lib) filterAttrs isDerivation mapAttrs;

  allPackages = mapAttrs (name: pkg: callPackage pkg { }) files.packages;
in
{
  # All custom packages
  legacyPackages = allPackages;

  # Custom packages, derivations only
  packages = (filterAttrs (name: pkg: isDerivation pkg) allPackages);
}
