{ lib, my, ... }:

let
  inherit (builtins) elem mapAttrs;
  inherit (lib) filterAttrs;
  inherit (my.lib) getImportableExcept;
in

{
  flake.packagesFunc = pkgs:
    filterAttrs (n: p: ! p ? meta || ! p.meta ? platforms || elem pkgs.system p.meta.platforms) (
      mapAttrs (n: v: pkgs.callPackage v {}) (getImportableExcept ./. [ "default" ])
    )
  ;
}
