# onix

❄️ A Nix Flake to help configure all your computers in one central repo ❄️

## Features

- 🤖 Auto-generates Nix configs based on your directory structure
- 🛠️ Builds NixOS configs with your modules and packages included
- 📦 Generates Flake outputs for easy usage and collaboration
- 🏠 Simple Home Manager integration for NixOS and non-NixOS systems
- 🐚 Creates a dev shell with convenient aliases for common NixOS commands

## Usage

Get started quickly by using the template:

```sh
  nix flake init -t github:computerdane/onix/v0.1.0
```

Or, build your own Flake from scratch:

```nix
  {
    description = "a flake based on onix";

    inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      onix.url = "github:computerdane/onix/v0.1.0";
    };

    outputs =
      { nixpkgs, onix, ... }:
      onix.init {
        inherit nixpkgs;
        src = ./.;
      };
  }
```

## Directory Structure

Example:

```
  ├── flake.nix
  ├── configuration.nix                   Shared NixOS config
  ├── home.nix                            Shared Home Manager config
  ├── hosts                               Define hosts to build
  │   ├── pc.nix
  │   └── laptop.nix
  ├── configs                             NixOS system configs
  │   └── pc
  │       ├── configuration.nix
  │       └── hardware-configuration.nix
  ├── modules                             NixOS modules
  │   ├── dynamic-dns.nix
  │   └── router
  │       ├── module.nix
  │       └── setup-subnets.nix
  ├── hm-configs                          Home Manager configs
  │   ├── media-utils.nix
  │   └── editor
  │       ├── home.nix
  │       └── language-settings.nix
  ├── hm-modules                          Home Manager modules
  │   ├── epic-shell.nix
  │   └── my-library
  │       ├── module.nix
  │       └── some-utils.nix
  └── packages                            Custom packages
      ├── echo-green.nix
      └── funnyfetch
          ├── package.nix
          └── script.sh
```

- `hosts`: Looks for `.nix` files
- `configs`: Looks for `.nix` files or directories with a `configuration.nix`
- `modules`: Looks for `.nix` files or directories with a `module.nix`
- `hm-configs`: Looks for `.nix` files or directories with a `home.nix`
- `hm-modules`: Looks for `.nix` files or directories with a `module.nix`
- `packages`: Looks for `.nix` files or directories with a `package.nix`

## Outputs

Your directory tree is scanned and the following Flake outputs are automatically
made available:

- `nixosModules.${module}` - NixOS modules
- `homeManagerModules.${module}` - Home Manager modules
- `packages.${system}.${package}` - Packages for each of your systems
- `legacyPackages.${system}.homeConfigurations."${user}@${host}"` - Home Manager
  configs for each user and host
- `nixosConfigurations.${host}` - NixOS configurations for each host
- `devShells.${system}` - A dev shell with some useful aliases
- `overlays.default` - A nixpkgs overlay that includes all your packages

## Dev Shell

To use the dev shell, use `nix develop` on your onix Flake.

- `oswitch [name]` - Switch to a configuration (name is optional)
- `ohmswitch [name]` - Switch to a Home Manager configuration (name is optional)
- `obuild <name>` - Build a configuration
- `odeploy <name> <host>` - Build a configuration and deploy it to an SSH host
