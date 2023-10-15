inputs@{ nixpkgs-unstable, self, ... }:
let
  inherit (nixpkgs-unstable.lib) genAttrs;
in
genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
  self.packagesFunc nixpkgs-unstable.legacyPackages."${system}"
)
