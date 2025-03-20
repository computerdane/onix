{ lib }:

with lib;
with lib.types;

{
  settings = mkOption {
    type = attrsOf str;
    default = {
      my-option = "my-value";
      hello = "world";
    };
  };
}
