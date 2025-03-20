# onix

❄️ A nix Flake to help you configure multiple computers in one central repo ❄️

## Features

- 🤖 Auto-generates Nix configs based on your directory structure
- 🛠️ Builds NixOS configurations with your modules and packages included
- 📦 Outputs your modules and packages as Flake outputs for easy collaboration
- 🐚 Creates a dev shell with simple aliases for common NixOS commands

## Usage

Get started quickly by using the template:

```sh
  nix flake init -t github:computerdane/onix/v0.0.2
```

Or, build your own Flake from scratch:

```nix
  {
    description = "a flake based on onix";

    inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      onix.url = "github:computerdane/onix/v0.0.2";
      onix.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs =
      { onix, ... }:
      onix.init {
        src = ./.;
        modules = [ ];     # Optional: import modules from other flakes here
        overlays = { };    # Optional: add your own nixpkgs overlays
        specialArgs = { }; # Optional: pass extra arguments to your configs
      };
  }
```

## Directory Structure

Example:

```
  ├── flake.nix
  ├── configuration.nix                   Shared config for all hosts
  ├── hosts                               Define your hosts' architectures
  │   └── pc.nix
  ├── configs                             NixOS system configurations
  │   └── pc
  │       ├── configuration.nix
  │       └── hardware-configuration.nix
  ├── modules                             Modules from all subdirectories
  │   ├── bar.nix
  │   ├── baz
  │   │   ├── module.nix
  │   │   └── types.nix
  │   └── foo.nix
  └── packages                            Packages from all subdirectories
      ├── echo-green.nix
      └── funnyfetch
          ├── package.nix
          └── script.sh
```

- `hosts`: Looks for `.nix` files
- `configs`: Looks for `.nix` files or folders with a `configuration.nix`
- `modules`: Looks for `.nix` files or folders with a `module.nix`
- `packages`: Looks for `.nix` files or folders with a `package.nix`

## Outputs

Your modules and packages are made available in the `nixosModules` and
`packages` Flake outputs. Your system configurations are made available in the
`nixosConfigurations` output. There is also a `devShell` with useful aliases
for system management.

## Dev Shell

To use the dev shell, use `nix develop` on your onix Flake.

- `oswitch [name]` - Switch to a configuration (hostname is optional)
- `obuild <name>` - Build a configuration
- `odeploy <name> <host>` - Build a configuration and deploy it to an SSH host
