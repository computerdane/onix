{ nixpkgs, home-manager }:

{
  olib ? import ./olib.nix { inherit nixpkgs; },

  # The user's project root
  src,

  # Allow the user to import some of their own stuff
  modules ? [ ],
  specialArgs ? { },
  overlays ? { },
  hmModules ? [ ],
  hmSpecialArgs ? { },

  onix ?
    let
      inherit (nixpkgs.lib.path) append;
    in
    {
      # Read the directory tree and import all necessary files

      config = olib.importOrEmpty (append src "configuration.nix");
      configs = olib.importNixFilesRecursive "configuration" (append src "configs");
      hosts = olib.importNixFiles (append src "hosts");
      modules = olib.importNixFilesRecursive "module" (append src "modules");
      packages = olib.importNixFilesRecursive "package" (append src "packages");

      hm-config = olib.importOrEmpty (append src "home.nix");
      hm-configs = olib.importNixFilesRecursive "home" (append src "hm-configs");
      hm-modules = olib.importNixFilesRecursive "module" (append src "hm-modules");
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
  homeManagerModules = onix.hm-modules;

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
        # Export a config named `${username}.${host}` for each host and each
        # user defined in the hosts folder
        homeConfigurations = builtins.listToAttrs (
          flatten (
            # For each host
            mapAttrsToList (
              host:
              {
                users ? { },
                ...
              }:
              # And each user in that host
              mapAttrsToList (
                username:
                { hm-configs }:
                {
                  # Make a home-manager config labeled `${username}.${host}`
                  name = "${username}@${host}";
                  value = home-manager.lib.homeManagerConfiguration {
                    inherit pkgs;
                    modules = import ./home-manager-modules.nix {
                      inherit
                        nixpkgs
                        username
                        onix
                        overlaysModule
                        hmModules
                        ;
                      hm-config-names = hm-configs;
                    };
                    extraSpecialArgs = hmSpecialArgs;
                  };
                }
              ) users
            ) onix.hosts
          )
        );
      }))
    );

  # Create a dev shell with some useful aliases
  devShells = olib.eachDefaultSystemPkgs (pkgs: {
    default = pkgs.mkShell { buildInputs = pkgs.callPackage ./scripts.nix { }; };
  });

  # Output nixos configs for each host
  nixosConfigurations =
    let
      inherit (nixpkgs.lib)
        nixosSystem
        flatten
        attrValues
        filterAttrs
        ;
    in
    builtins.mapAttrs (
      name:
      {
        system,
        users ? { },
      }:
      let
        homeManagerNixosModules =
          if users != { } then
            [
              home-manager.nixosModules.home-manager
              (import ./home-manager-nixos-modules.nix {
                inherit
                  nixpkgs
                  users
                  onix
                  overlaysModule
                  hmModules
                  hmSpecialArgs
                  ;
              })
            ]
          else
            [ ];
      in
      nixosSystem {
        inherit system specialArgs;
        modules = flatten [
          (import ./host-name-module.nix name)
          onix.config
          onix.configs.${name}
          (attrValues onix.modules)
          overlaysModule
          modules
          homeManagerNixosModules
        ];
      }
    ) (filterAttrs (name: host: (host.homeManagerOnly or false) == false) onix.hosts);
}
