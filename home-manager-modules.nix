{
  nixpkgs,
  username,
  onix,
  home-config-name,
  overlaysModule,
  homeModules,
}:

let
  inherit (nixpkgs.lib) flatten attrValues;
in
flatten [
  (import ./home.nix username)
  onix.home-config
  onix.home-configs.${home-config-name}
  (attrValues onix.home-modules)
  overlaysModule
  homeModules
]
