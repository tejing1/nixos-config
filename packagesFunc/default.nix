inputs@{ nixpkgs, self, ... }:
pkgs:
let
  inherit (builtins) length head attrValues;
  inherit (nixpkgs.lib) zipAttrsWith;
  inherit (self.lib) importAllExceptWithArg;
in
zipAttrsWith (n: v: assert length v == 1; head v) (
  attrValues (
    importAllExceptWithArg ./. [ "default.nix" ] (inputs // { inherit pkgs; })
  )
)
