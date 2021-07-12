{ self, nixpkgs, ... }:
let
  inherit (nixpkgs.lib) fileContents;
  inherit (self.lib) mkHome listImportablePathsExcept;
in

mkHome (listImportablePathsExcept ./. [ "default.nix" ]) (fileContents ./system)
