{ nixpkgs }:

{
  src,
  modules ? [ ],
  specialArgs ? { },
  overlays ? { },
  olib ? import ./olib.nix { inherit nixpkgs; },
  onix ?
    let
      inherit (nixpkgs.lib.path) append;
    in
    {
      config = olib.importOrEmpty (append src "configuration.nix");
      configs = olib.importNixFilesRecursive "configuration" (append src "configs");
      hosts = olib.importNixFiles (append src "hosts");
      modules = olib.importNixFilesRecursive "module" (append src "modules");
      packages = olib.importNixFilesRecursive "package" (append src "packages");
    },
  defaultOverlay ? final: prev: (olib.callAllPackages prev onix.packages),
  overlayList ? nixpkgs.lib.flatten [
    (nixpkgs.lib.attrValues overlays)
    defaultOverlay
  ],
}:

{
  nixosModules = onix.modules;
  overlays.default = defaultOverlay;

  packages =
    let
      inherit (nixpkgs.lib) filterAttrs isDerivation;
    in
    olib.eachDefaultSystemPkgs (
      pkgs: (filterAttrs (n: v: isDerivation v) (olib.callAllPackages pkgs onix.packages))
    );

  devShells = olib.eachDefaultSystemPkgs (pkgs: {
    default = pkgs.mkShell { buildInputs = pkgs.callPackage ./scripts.nix { }; };
  });

  nixosConfigurations = builtins.mapAttrs (
    name:
    { system }:
    let
      inherit (nixpkgs.lib) nixosSystem flatten attrValues;
    in
    nixosSystem {
      inherit system specialArgs;
      modules = flatten [
        (import ./host-name.nix name)
        onix.config
        onix.configs.${name}
        (attrValues onix.modules)
        (import ./overlays.nix { inherit overlayList; })
        modules
      ];
    }
  ) onix.hosts;
}
