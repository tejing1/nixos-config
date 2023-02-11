inputs@{ nixpkgs, self, ... }:
pkgs:
let
  inherit (builtins) length head attrValues elem;
  inherit (nixpkgs.lib) zipAttrsWith filterAttrs;
  inherit (self.lib) importAllExceptWithArg;
in
filterAttrs (n: p: ! p ? meta || ! p.meta ? platforms || elem pkgs.system p.meta.platforms) (
  zipAttrsWith (n: v: assert length v == 1; head v) (
    attrValues (
      importAllExceptWithArg ./. [ "default.nix" ] (inputs // { inherit pkgs; })
    )
  )
)
