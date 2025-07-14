{ lib, ... }:

let
  inherit (builtins) concatMap attrValues concatStringsSep;
  inherit (lib) unique;

  flakesClosure = flakes: if flakes == [] then [] else unique (flakes ++ flakesClosure (concatMap (flake: if flake ? inputs then attrValues flake.inputs else []) flakes));
in

{
  perPkgs = { pkgs, ... }: {
    my.lib.flakeClosureRef = flake: pkgs.writeText "flake-closure" (concatStringsSep "\n" (flakesClosure [ flake ]) + "\n");
  };
}
