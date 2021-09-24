{ nixpkgs, self, ... }:
let
  inherit (nixpkgs.lib) fileContents;
  inherit (self.lib) mkNixos listImportablePathsExcept;
in

mkNixos (listImportablePathsExcept ./. [ "default.nix" ]) (fileContents ./system)
