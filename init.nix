{ nixpkgs, home-manager }:

{
  olib ? import ./olib.nix { inherit nixpkgs; },

  # The user's project root
  src,

  # Allow the user to import some of their own stuff
  modules ? [ ],
  specialArgs ? { },
  overlays ? { },
  homeModules ? [ ],
  homeSpecialArgs ? { },

  onix ?
    let
      inherit (nixpkgs.lib.path) append;
    in
    {
      # Read the directory tree and import all necessary files
      config = olib.importOrEmpty (append src "configuration.nix");
      configs = olib.importNixFilesRecursive "configuration" (append src "configs");
      home-config = olib.importOrEmpty (append src "home.nix");
      home-configs = olib.importNixFilesRecursive "home" (append src "home-configs");
      home-modules = olib.importNixFilesRecursive "module" (append src "home-modules");
      hosts = olib.importNixFiles (append src "hosts");
      modules = olib.importNixFilesRecursive "module" (append src "modules");
      packages = olib.importNixFilesRecursive "package" (append src "packages");
      users = olib.importNixFiles (append src "users");
    },

  # Overlay that adds all custom packages
  defaultOverlay ? final: prev: (olib.callAllPackages prev onix.packages),

  # Overlays as a list
  overlaysList ? nixpkgs.lib.flatten [
    (nixpkgs.lib.attrValues overlays)
    defaultOverlay
  ],

  # NixOS that applies overlays
  overlaysModule ? (import ./overlays.nix { inherit overlaysList; }),
}:

{
  # Make custom modules available as outputs
  nixosModules = onix.modules;

  # Output an overlay for others to import custom packages
  overlays.default = defaultOverlay;

  # Individual package outputs
  packages = (
    let
      inherit (nixpkgs.lib) filterAttrs isDerivation;
    in
    # Custom packages (derivations only)
    olib.eachDefaultSystemPkgs (
      pkgs: (filterAttrs (n: v: isDerivation v) (olib.callAllPackages pkgs onix.packages))
    )
  );

  legacyPackages =
    # All custom packages
    (olib.eachDefaultSystemPkgs (pkgs: olib.callAllPackages pkgs onix.packages))
    // (
      let
        inherit (nixpkgs.lib) flatten mapAttrsToList;
      in
      # Home manager configurations
      (olib.eachDefaultSystemPkgs (pkgs: {
        # Export a config named `${username}.${config}` for each user in the
        # users folder and each config they are assigned to use
        homeConfigurations = builtins.listToAttrs (
          flatten (
            mapAttrsToList (
              username: user:
              (map (home-config-name: {
                name = "${username}.${home-config-name}";
                value = home-manager.lib.homeManagerConfiguration {
                  inherit pkgs;
                  modules = import ./home-manager-modules.nix {
                    inherit
                      nixpkgs
                      username
                      onix
                      home-config-name
                      overlaysModule
                      homeModules
                      ;
                  };
                  extraSpecialArgs = homeSpecialArgs;
                };
              }) user.configs)
            ) onix.users
          )
        );
      }))
    );

  # Create a dev shell with some useful aliases
  devShells = olib.eachDefaultSystemPkgs (pkgs: {
    default = pkgs.mkShell { buildInputs = pkgs.callPackage ./scripts.nix { }; };
  });

  # Output nixos configs for each host
  nixosConfigurations = builtins.mapAttrs (
    name:
    {
      system,
      users ? { },
    }:
    let
      inherit (nixpkgs.lib) nixosSystem flatten attrValues;
      modulesForHomeManager =
        if users != { } then
          [
            home-manager.nixosModules.home-manager
            (import ./home-manager.nix {
              inherit
                nixpkgs
                users
                onix
                overlaysModule
                homeModules
                homeSpecialArgs
                ;
            })
          ]
        else
          [ ];
    in
    nixosSystem {
      inherit system specialArgs;
      modules = flatten [
        (import ./host-name.nix name)
        onix.config
        onix.configs.${name}
        (attrValues onix.modules)
        overlaysModule
        modules
        modulesForHomeManager
      ];
    }
  ) onix.hosts;
}
