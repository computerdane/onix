{
  extraHomeManagerModules,
  files,
  hm-configs,
  lib,
  username,
}:

let
  inherit (lib) attrValues flatten;
in

flatten [
  (
    { ... }:
    {
      home.username = username;
      programs.home-manager.enable = true;
    }
  )
  (attrValues files.hm-modules)
  files.hm-config
  (map (n: files.hm-configs.${n}) hm-configs)
  extraHomeManagerModules
]
