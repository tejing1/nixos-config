{ pkgs, my, ... }:
with builtins;
with pkgs;
with my.lib;

subs: name: src:
# generate a file named 'name' from a 'src' template containing
# @foo@-style references which are expanded to corresponding values in
# the 'subs' attrset
writeScript name (readTemplate subs src)
