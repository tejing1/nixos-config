inputs@{ nixpkgs, ... }:

with builtins;
with nixpkgs.lib;
listToAttrs (
  map
    ( n:
      {
        name = n;
        value = import (./. + "/${n}") inputs;
      }
    )
    (
      attrNames (
        filterAttrs
          ( n: v:
            v == "directory" && pathExists (./. + "/${n}/default.nix")
          )
          (
            readDir ./.
          )
      )
    )
)
