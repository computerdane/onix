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
    filterAttrs
    flatten
    isDerivation
    mapAttrs
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

in

rec {
  # Custom modules
  nixosModules = files.modules;
  homeManagerModules = files.hm-modules;

  # All custom packages
  legacyPackages = mapAttrs (name: pkg: callPackage pkg { }) files.packages;

  # Custom packages, derivations only
  packages = filterAttrs (name: pkg: isDerivation pkg) legacyPackages;

  # Overlay that imports all custom packages
  overlays.default = final: prev: packages;

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
