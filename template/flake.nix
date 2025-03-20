{
  description = "a template based on onix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    onix.url = "github:computerdane/onix/v0.0.1";
    onix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { onix, ... }: onix.init { src = ./.; };
}
