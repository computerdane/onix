{
  lib,
# defaultSystems ? [
#   "aarch64-linux"
#   "aarch64-darwin"
#   "x86_64-darwin"
#   "x86_64-linux"
# ],
}:

let
  inherit (lib)
    flatten
    mapAttrs'
    nameValuePair
    filterAttrs
    mapAttrsToList
    append
    hasSuffix
    removeSuffix
    ;
in

rec {
  # Gets the file name without the parent directory from a path
  fileNameOf = path: baseNameOf (toString path);

  # Check if a file has the .nix extension
  isNixFile = path: hasSuffix ".nix" (fileNameOf path);

  # Remove the .nix extension from a path
  withoutNixExt = path: removeSuffix ".nix" (fileNameOf path);

  # List all of the .nix files in a directory
  listNixFiles =
    dir:
    if builtins.pathExists dir then
      filterAttrs (path: type: type == "regular" && isNixFile path) (builtins.readDir dir)
    else
      [ ];

  # List all the .nix files in a directory tree, preferring a default file name
  listNixFilesRecursive =
    defaultFileName: dir:
    let
      defaultPath = append dir "${defaultFileName}.nix";
    in
    if builtins.pathExists defaultPath then
      # if `${dir}/${defaultFile}` exists, include only the default file
      [
        {
          path = defaultPath;
          name = fileNameOf dir;
        }
      ]
    else if builtins.pathExists dir then
      # otherwise, include all .nix files and keep traversing the tree
      builtins.filter (e: isNixFile e.path) (
        flatten (
          mapAttrsToList (
            name: type:
            let
              path = append dir name;
            in
            if type == "directory" then
              listNixFilesRecursive defaultFileName path
            else
              {
                inherit path;
                name = withoutNixExt path;
              }
          ) (builtins.readDir dir)
        )
      )
    else
      [ ];

  # Import all of the .nix files in a directory
  importNixFiles =
    dir:
    if builtins.pathExists dir then
      mapAttrs' (name: type: nameValuePair (withoutNixExt name) (import (append dir name))) (
        listNixFiles dir
      )
    else
      { };

  # Generate an attrset with all the .nix files from listNixFilesRecursive imported
  importNixFilesRecursive =
    defaultFileName: dir:
    builtins.listToAttrs (
      map (
        { path, name }:
        {
          inherit name;
          value = import path;
        }
      ) (listNixFilesRecursive defaultFileName dir)
    );

  # Imports a .nix file, and if it doesn't exist, returns a blank function
  importOrEmpty = path: if builtins.pathExists path then import path else { ... }: { };
}
