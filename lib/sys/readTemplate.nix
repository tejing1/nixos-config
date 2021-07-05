{ lib, my, ... }:
with builtins;
with lib;
with my.lib;

subs: src:
# generate a string from a 'src' template containing @foo@-style
# references which are expanded to corresponding values in the 'subs'
# attrset
# TODO: make this handle deep references like @a.b.c@
let
  contents = if isPath src then readFile src else src;
  needed = filter (n: ! isNull (match ".*@(${n})@.*" contents)) (attrNames subs);
in
replaceStrings (map (n: "@" + n + "@") needed) (map (n: toString subs."${n}") needed) contents
