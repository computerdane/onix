{
  nixpkgs,
  username,
  onix,
  hm-config-name,
  overlaysModule,
  hmModules,
}:

let
  inherit (nixpkgs.lib) flatten attrValues;
in
flatten [
  (import ./home.nix username)
  onix.hm-config
  onix.hm-configs.${hm-config-name}
  (attrValues onix.hm-modules)
  overlaysModule
  hmModules
]
