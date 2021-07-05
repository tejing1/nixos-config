{lib, my, ... }:
with builtins;
with lib;
with my.lib;

dir:
# list importable filenames in the directory 'dir',
let
  conditionTable = n: {
    regular = hasSuffix ".nix" n;
    directory = pathExists (dir + "/${n}/default.nix");
  };
in
attrNames (filterAttrs (n: v: getAttrWithDefault false v (conditionTable n)) (readDir dir))
