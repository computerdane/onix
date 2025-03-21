{
  olib,
  lib,
  callPackage,
  nixos,
}:

{
  src,

  extraModules ? [ ],
  extraOverlays ? { },
}:

let

  inherit (lib)
    attrValues
    filterAttrs
    flatten
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

  # Custom packages
  packages = mapAttrs (name: pkg: callPackage pkg { }) files.packages;

  # Overlay that imports all custom packages
  overlays.default = final: prev: packages;

  # NixOS configuration for each host
  nixosConfigurations =
    let
      nixosHosts = (filterAttrs (name: host: (host.homeManagerOnly or false) == false) files.hosts);
    in
    mapAttrs (
      name: host:
      nixos (flatten [
        (mkModule.hostName name)
        (mkModule.overlays overlays)

        (mkModule.overlays extraOverlays)
        extraModules

        (attrValues files.modules)

        files.config
        files.configs.${name}
      ])
    ) nixosHosts;
}
