{ config, lib, ... }:

let
  cfg = config.programs.custom-btop;
in
{
  options.programs.custom-btop.enable = lib.mkEnableOption "my custom btop";

  config = lib.mkIf cfg.enable {

    programs.btop = {
      enable = true;
      settings = {
        color_theme = "Dracula";
        theme_background = false;
        update_ms = 100;
      };
    };

  };
}
