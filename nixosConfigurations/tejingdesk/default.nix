{ self, nixpkgs, ... }:
with nixpkgs.lib;
with self.lib;

mkNixos (listImportablePathsExcept ./. [ "default.nix" ]) (fileContents ./system)
