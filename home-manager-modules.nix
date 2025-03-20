{
  nixpkgs,
  username,
  onix,
  hm-config-names,
  overlaysModule,
  hmModules,
}:

let
  inherit (nixpkgs.lib) flatten attrValues;
  configs = flatten (map (name: onix.hm-configs.${name}) hm-config-names);
in
flatten [
  (import ./home.nix username)
  onix.hm-config
  configs
  (attrValues onix.hm-modules)
  overlaysModule
  hmModules
]
