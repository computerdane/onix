{
  outputs =
    { ... }:
    {
      init = import ./init.nix;
      templates.default = {
        path = ./template;
        description = "minimal template with onix directory structure";
      };
    };
}
