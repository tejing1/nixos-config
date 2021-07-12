{lib, my, ... }:
let
  inherit (builtins) pathExists attrNames readDir;
  inherit (lib) hasSuffix filterAttrs;
  inherit (my.lib) getAttrWithDefault;
in

dir:
# list importable filenames in the directory 'dir',
let
  conditionTable = n: {
    regular = hasSuffix ".nix" n;
    directory = pathExists (dir + "/${n}/default.nix");
  };
in
attrNames (filterAttrs (n: v: getAttrWithDefault false v (conditionTable n)) (readDir dir))
