{ pkgs, my, ... }:
let
  inherit (pkgs) writeScript;
  inherit (my.lib) readTemplate;
in

subs: name: src:
# generate a file named 'name' from a 'src' template containing
# @foo@-style references which are expanded to corresponding values in
# the 'subs' attrset
writeScript name (readTemplate subs src)
