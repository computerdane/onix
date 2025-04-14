{
  nixpkgs,
  home-manager ? null,

  src,

  extraModules ? [ ],
  extraHomeManagerModules ? [ ],

  extraSpecialArgs ? { },
  extraHomeManagerSpecialArgs ? { },

  installHelperScripts ? false,
}:

let
  lib = nixpkgs.lib;

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

  # Read source tree and import all modules
  files = {
    config = olib.importOrEmpty (append src "configuration.nix");
    configs = olib.importNixFilesRecursive "configuration" (append src "configs");
    hosts = olib.importNixFiles (append src "hosts");
    modules = olib.importNixFilesRecursive "module" (append src "modules");
    packages = olib.importNixFilesRecursive "package" (append src "packages");

    hm-config = olib.importOrEmpty (append src "home.nix");
    hm-configs = olib.importNixFilesFromSubdirsRecursive "home" (append src "hm-configs");
    hm-modules = olib.importNixFilesRecursive "module" (append src "hm-modules");
  };

  # Grab unique systems from `hosts/`
  systems = unique (mapAttrsToList (name: host: host.system) files.hosts);

  # Overlay that imports all custom packages
  overlays.default = final: prev: mapAttrs (name: pkg: prev.callPackage pkg { }) files.packages;

in

rec {
  inherit overlays;

  # Custom modules
  nixosModules = files.modules;
  homeManagerModules = files.hm-modules;

  # NixOS configuration for each host
  nixosConfigurations =
    let
      nixosHosts = (filterAttrs (hostname: host: !(host.homeManagerOnly or false)) files.hosts);
    in
    mapAttrs (
      hostname:
      {
        system,
        ...
      }:
      let
        homeManagerNixosModules = import ./home-manager-nixos-modules.nix {
          inherit
            extraHomeManagerModules
            extraHomeManagerSpecialArgs
            files
            home-manager
            hostname
            installHelperScripts
            lib
            olib
            overlays
            ;
        };
        modules = flatten [
          (
            { lib, pkgs, ... }:
            {
              networking.hostName = hostname;
              nixpkgs.overlays = [ overlays.default ];
              environment.systemPackages = lib.mkIf installHelperScripts (pkgs.callPackage ./scripts.nix { });
            }
          )
          (attrValues files.modules)
          files.config
          files.configs.${hostname}
          extraModules
          homeManagerNixosModules
        ];
      in
      lib.nixosSystem {
        inherit system modules;
        specialArgs = extraSpecialArgs;
      }
    ) nixosHosts;

}
// (
  # Create the per-system flake outputs
  olib.eachSystem systems (
    system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlays.default ];
      };
    in
    pkgs.callPackage ./per-system.nix {
      inherit
        extraHomeManagerModules
        extraHomeManagerSpecialArgs
        files
        home-manager
        installHelperScripts
        olib
        overlays
        ;
    }
  )
)
