{ my, pkgs, ... }:
let
  inherit (pkgs) writeScriptBin;
  inherit (my.lib) readTemplate;
in

subs: name: src:
# generate a package with name 'name' with a single binary also named
# 'name' from a 'src' template containing @foo@-style references which
# are expanded to corresponding values in the 'subs' attrset
writeScriptBin name (readTemplate subs src)
