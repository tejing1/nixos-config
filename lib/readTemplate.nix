{ lib, ... }:
let
  inherit (builtins) isPath isList readFile filter match replaceStrings;
  inherit (lib) splitString hasAttrByPath getAttrFromPath;
in

subs: src:
# generate a string from a 'src' template containing @foo@-style
# references which are expanded to corresponding values in the 'subs'
# attrset
let
  contents = if isPath src then readFile src else src;
  isValid = s:
    # the string is a sequence of dot-separated valid nix identifiers.
    isList (builtins.match "([a-zA-Z_][a-zA-Z0-9_'-]*(.[a-zA-Z_][a-zA-Z0-9_'-]*)*)" s) &&
    # the path actually exists in subs
    hasAttrByPath (splitString "." s) subs;
  needed = filter isValid (splitString "@" contents);
in
replaceStrings (map (s: "@" + s + "@") needed) (map (s: toString (getAttrFromPath (splitString "." s) subs)) needed) contents
