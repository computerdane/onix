# foo.nix - an example NixOS module

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.foo;
in
{
  options.foo.enable = lib.mkEnableOption "foo";

  config = lib.mkIf cfg.enable {

    environment.systemPackages = [ pkgs.asciiquarium ];

  };
}
