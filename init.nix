{
  olib,
  lib,
  callPackage,
}:

{
  src,

  nixpkgsConfig ? { },

  extraModules ? [ ],
  extraOverlays ? { },
}:

let

  inherit (lib)
    attrValues
    concatMapAttrs
    filterAttrs
    flatten
    isDerivation
    listToAttrs
    mapAttrs
    mapAttrsToList
    unique
    ;
  inherit (lib.path) append;

  files = {
    config = olib.importOrEmpty (append src "configuration.nix");
    configs = olib.importNixFilesRecursive "configuration" (append src "configs");
    hosts = olib.importNixFiles (append src "hosts");
    modules = olib.importNixFilesRecursive "module" (append src "modules");
    packages = olib.importNixFilesRecursive "package" (append src "packages");

    hm-config = olib.importOrEmpty (append src "home.nix");
    hm-configs = olib.importNixFilesRecursive "home" (append src "hm-configs");
    hm-modules = olib.importNixFilesRecursive "module" (append src "hm-modules");
  };

  systems = unique (mapAttrsToList (name: host: host.system) files.hosts);
  eachSystem =
    attrs:
    concatMapAttrs (
      name: value:
      listToAttrs (
        map (system: {
          name = system;
          value.${name} = value;
        }) systems
      )
    ) attrs;

  mkModule = {
    hostName =
      name:
      { ... }:
      {
        networking.hostName = name;
      };

    overlays =
      overlays:
      { ... }:
      {
        nixpkgs.overlays = attrValues overlays;
      };
  };

  allPackages = mapAttrs (name: pkg: callPackage pkg { }) files.packages;

in

rec {
  # Custom modules
  nixosModules = files.modules;
  homeManagerModules = files.hm-modules;

  # All custom packages
  legacyPackages = eachSystem allPackages;

  # Custom packages, derivations only
  packages = eachSystem (filterAttrs (name: pkg: isDerivation pkg) allPackages);

  # Overlay that imports all custom packages
  overlays.default = final: prev: allPackages;

  # NixOS configuration for each host
  nixosConfigurations =
    let
      nixosHosts = (filterAttrs (name: host: (host.homeManagerOnly or false) == false) files.hosts);
    in
    mapAttrs (
      name: host:
      let
        pkgs = import <nixpkgs> {
          system = host.system;
          overlays = flatten [
            (attrValues overlays)
            (attrValues extraOverlays)
          ];
          config = nixpkgsConfig;
        };
      in
      pkgs.nixos (flatten [
        (mkModule.hostName name)
        (attrValues files.modules)
        files.config
        files.configs.${name}
        extraModules
      ])
    ) nixosHosts;
}
