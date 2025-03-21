{
  nixpkgs,
  olib,
}:

{
  src,

  extraModules ? [ ],
  extraOverlays ? { },
}:

let

  inherit (nixpkgs.lib)
    attrValues
    filterAttrs
    flatten
    mapAttrs
    mapAttrsToList
    concatMapAttrs
    unique
    ;
  inherit (nixpkgs.lib.path) append;

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
      builtins.listToAttrs (
        map (system: {
          inherit name;
          value.${system} = value;
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
      nixpkgs.lib.nixosSystem {
        system = host.system;
        modules = flatten [
          (mkModule.hostName name)
          (mkModule.overlays overlays)
          (mkModule.overlays extraOverlays)
          (attrValues files.modules)
          files.config
          files.configs.${name}
          extraModules
        ];
      }
    ) nixosHosts;
}
// (eachSystem (
  system:
  let
    pkgs = import nixpkgs { inherit system; };
  in
  pkgs.callPackage ./per-system.nix { inherit files; }
))
