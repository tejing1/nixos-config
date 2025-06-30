inputs@{ nixpkgs, self, ... }:
pkgs:
let
  inherit (builtins) elem mapAttrs;
  inherit (pkgs.lib) filterAttrs;
  inherit (self.lib) importAllExcept;
in
filterAttrs (n: p: ! p ? meta || ! p.meta ? platforms || elem pkgs.system p.meta.platforms) (
  mapAttrs (n: v: pkgs.callPackage v {}) (importAllExcept ./. [ "default" ])
)
