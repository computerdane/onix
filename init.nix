{ nixpkgs, utils }:

{
  src,
  modules ? [ ],
  specialArgs ? { },
  overlays ? [ ],
  olib ? import ./olib.nix { lib = nixpkgs.lib; },
  onix ?
    let
      inherit (nixpkgs.lib.path) append;
    in
    {
      config = olib.importOrEmpty (append src "configuration.nix");
      configs = olib.importNixFiles (append src "configs");
      hardwareConfigs = olib.importNixFiles (append src "hardware-configs");
      hosts = olib.importNixFiles (append src "hosts");
      modules = olib.importNixFilesRecursive "module" (append src "modules");
      packages = olib.importNixFilesRecursive "package" (append src "packages");
    },
}:

{
  nixosModules = onix.modules;

  packages =
    (utils.lib.eachDefaultSystem (
      system:
      let
        inherit (nixpkgs.lib) filterAttrs isDerivation;
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = (filterAttrs (n: v: isDerivation v) (olib.callAllPackages pkgs onix.packages));
      }
    )).packages;

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
        onix.hardwareConfigs.${name}
        (attrValues onix.modules)
        (import ./overlays.nix { inherit olib onix overlays; })
        modules
      ];
    }
  ) onix.hosts;
}
