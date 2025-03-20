{
  nix,
  nixos-rebuild,
  openssh,
  writeShellApplication,
}:

[
  (writeShellApplication {
    name = "oswitch";
    runtimeInputs = [ nixos-rebuild ];
    text = ''
      set +u
      sudo nixos-rebuild switch -v --flake .#"$1"
    '';
  })
  (writeShellApplication {
    name = "obuild";
    runtimeInputs = [ nix ];
    text = ''
      nix build -v .#nixosConfigurations."$1".config.system.build.toplevel --show-trace
    '';
  })
  (writeShellApplication {
    name = "odeploy";
    runtimeInputs = [
      nix
      openssh
    ];
    text = ''
      BUILD_DIR="./result-$1"

      nix build ".#nixosConfigurations.$1.config.system.build.toplevel" -o "$BUILD_DIR" && \
        nix copy --to "ssh://$2" "$BUILD_DIR" -v && \
        ssh -t "$2" "sudo $(readlink "$BUILD_DIR")/bin/switch-to-configuration switch"
    '';
  })
]
