inputs@{ nixpkgs, self, ... }:
let
  inherit (nixpkgs.lib) genAttrs;
in
genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
  self.packagesFunc nixpkgs.legacyPackages."${system}"
)
