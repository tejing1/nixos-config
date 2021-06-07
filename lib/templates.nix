{ pkgs, my, ... }:

{
  my.readTemplate = with builtins; subs: src:
    let
      contents = if isPath src then readFile src else src;
      needed = filter (n: ! isNull (match ".*@(${n})@.*" contents)) (attrNames subs);
    in
      replaceStrings (map (n: "@" + n + "@") needed) (map (n: toString subs."${n}") needed) contents;
  my.templateScript = subs: name: src: pkgs.writeScript name (my.readTemplate subs src);
  my.templateScriptBin = subs: name: src: pkgs.writeScriptBin name (my.readTemplate subs src);
}
