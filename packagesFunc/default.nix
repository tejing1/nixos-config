{ lib, my, mylib, ... }:

let
  inherit (builtins) elem;
  inherit (lib) mkOption types filterAttrs;
  inherit (types) functionTo attrsOf;
in

{
  imports = mylib.listImportablePathsExcept ./. [ "default" ];

  options.my.pkgsFunc = mkOption {
    type = functionTo (attrsOf types.package);
  };

  config.flake.packagesFunc = pkgs: filterAttrs (n: p: ! p ? meta || ! p.meta ? platforms || elem pkgs.system p.meta.platforms) (my.pkgsFunc pkgs);
}
