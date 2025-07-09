{lib, ... }:

let
  inherit (builtins)
    pathExists
    readDir
  ;
  inherit (lib)
    hasSuffix
    mapAttrs'
    nameValuePair
    removeSuffix
    filterAttrs
  ;
in

{
  my.lib.getImportable = dir:
    mapAttrs' (n: v:
      nameValuePair (removeSuffix ".nix" n) (dir + "/${n}")
    ) (
      filterAttrs (n: v:
        {
          regular = hasSuffix ".nix" n;
          directory = pathExists (dir + "/${n}/default.nix");
        }.${v} or false
      ) (
        readDir dir
      )
    )
  ;
}
