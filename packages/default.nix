inputs@{ nixpkgs, self, ... }:
let
  inherit (builtins) length head attrValues;
  inherit (nixpkgs.lib) genAttrs zipAttrsWith;
  inherit (self.lib) importAllExceptWithArg;
in
genAttrs [ "x86_64-linux" ] (system:
  zipAttrsWith (n: v: assert length v == 1; head v) (
    attrValues (
      importAllExceptWithArg ./. [ "default.nix" ] (inputs // { inherit system; })
    )
  )
)
