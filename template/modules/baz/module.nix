# baz.nix - an example NixOS module
#
# This demonstrates that if module.nix is present in a folder, only that file
# will be imported as a module, and all other nix files are ignored.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.baz;

  types = import ./types.nix { inherit lib; };
in
{
  options.baz.enable = lib.mkEnableOption "baz";
  options.baz.settings = types.settings;

  config = lib.mkIf cfg.enable {

    systemd.services."my-service" =
      let
        configFile = pkgs.writeText "config.json" (builtins.toJSON cfg.settings);
      in
      {
        path = [ pkgs.coreutils ];
        script = ''
          cat "${configFile}"
        '';
      };

  };
}
