inputs@{ nixpkgs, self, ... }:
let
  inherit (nixpkgs.lib) genAttrs;
  inherit (self.lib) importAllExceptWithArg;
in
genAttrs [ "x86_64-linux" ] (system:
  importAllExceptWithArg ./. [ "default" ] (inputs // { inherit system; })
)
