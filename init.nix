{
  flake ? true,
  nixpkgs,
  src,

  extraModules ? [ ],
  extraOverlays ? { },
  nixpkgsConfig ? { },
}:

let
  pkgs = if flake then null else import nixpkgs { config = nixpkgsConfig; };
  lib = if flake then nixpkgs.lib else pkgs.lib;

  inherit (lib)
    attrValues
    filterAttrs
    flatten
    mapAttrs
    mapAttrsToList
    unique
    ;
  inherit (lib.path) append;

  olib = import ./olib.nix { inherit lib; };

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

    nixpkgsConfig =
      c:
      { ... }:
      {
        nixpkgs.config = c;
      };
  };

in

rec {
  # Custom modules
  nixosModules = files.modules;
  homeManagerModules = files.hm-modules;

  # Overlay that imports all custom packages
  overlays.default = final: prev: mapAttrs (name: pkg: prev.callPackage pkg { }) files.packages;

  # NixOS configuration for each host
  nixosConfigurations =
    let
      nixosHosts = (filterAttrs (name: host: (host.homeManagerOnly or false) == false) files.hosts);
    in
    mapAttrs (
      name: host:
      let
        modules = flatten [
          (mkModule.hostName name)
          (mkModule.overlays overlays)
          (mkModule.overlays extraOverlays)
          (attrValues files.modules)
          files.config
          files.configs.${name}
          extraModules
        ];
      in
      if flake then
        lib.nixosSystem {
          system = host.system;
          modules = modules ++ [ (mkModule.nixpkgsConfig nixpkgsConfig) ];
        }
      else
        pkgs.nixos modules
    ) nixosHosts;
}
// (olib.eachSystem systems (
  system:
  let
    pkgs = import nixpkgs { inherit system; };
  in
  pkgs.callPackage ./per-system.nix { inherit files; }
))
