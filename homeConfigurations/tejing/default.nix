{ self, nixpkgs, ... }:
with nixpkgs.lib;
with self.lib;

mkHome (listImportablePathsExcept ./. [ "default.nix" ]) (fileContents ./system)
