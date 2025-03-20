# bar.nix - an example NixOS module

{
  config,
  lib,
  ...
}:

let
  cfg = config.bar;
in
{
  options.bar.enable = lib.mkEnableOption "bar";

  config = lib.mkIf cfg.enable {

    programs.git = {
      enable = true;
      config.init.defaultBranch = "main";
    };

  };
}
