{ lib }:

let
  inherit (lib)
    any
    attrNames
    filterAttrs
    flatten
    hasSuffix
    mapAttrs'
    mapAttrsToList
    mkIf
    mkMerge
    nameValuePair
    removeSuffix
    splitString
    ;
  inherit (lib.path) append;
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
      builtins.map (
        { path, name }:
        {
          inherit name;
          value = import path;
        }
      ) (listNixFilesRecursive defaultFileName dir)
    );

  # Imports a .nix file, and if it doesn't exist, returns a blank function
  importOrEmpty = path: if builtins.pathExists path then import path else { ... }: { };

  # From github:numtide/flake-utils
  # Builds a map from <attr>=value to <attr>.<system>=value for each system.
  eachSystem = eachSystemOp (
    # Merge outputs for each system.
    f: attrs: system:
    let
      ret = f system;
    in
    builtins.foldl' (
      attrs: key:
      attrs
      // {
        ${key} = (attrs.${key} or { }) // {
          ${system} = ret.${key};
        };
      }
    ) attrs (attrNames ret)
  );

  # Applies a merge operation accross systems.
  eachSystemOp =
    op: systems: f:
    builtins.foldl' (op f) { } systems;

  # Make sure the home-manager argument is not null
  assertHomeManagerIsNotNull =
    home-manager: value:
    if home-manager != null then
      value
    else
      throw "You must include the `home-manager` argument to onix.init if you set a user's `hm-configs` in a hosts file!";

  # Function to insert onix arg into special args
  withOnixArg =
    meta: specialArgs:
    specialArgs
    // {
      onix = {
        inherit meta;
        lib = {
          mkForHosts = hosts: cfg: mkIf (any (host: host == meta.host) hosts) cfg;
          mkForUsers = users: cfg: mkIf (any (user: user == meta.user) users) cfg;
          mapHostUser =
            hostAttrs:
            flatten (
              mapAttrsToList (
                hostnameStr: userAttrs:
                let
                  hostnames = splitString " " hostnameStr;
                in
                (builtins.map (
                  hostname:
                  (mapAttrsToList (
                    usernameStr: cfg:
                    let
                      usernames = splitString " " usernameStr;
                    in
                    (builtins.map (username: mkIf (hostname == meta.host && username == meta.user) cfg) usernames)
                  ) userAttrs)
                ) hostnames)
              ) hostAttrs
            );
        };
      };
    };
}
