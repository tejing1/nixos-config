{ config, pkgs, ... }:

{
  _module.args.mylib = config.lib.my;
  lib.my = rec {
    readTemplate = with builtins; subs: src:
      let
        contents = if isPath src then readFile src else src;
        needed = filter (n: ! isNull (match ".*@(${n})@.*" contents)) (attrNames subs);
      in
        replaceStrings (map (n: "@" + n + "@") needed) (map (n: toString subs."${n}") needed) contents;
    templateScript = subs: name: src: pkgs.writeScript name (readTemplate subs src);
    templateScriptBin = subs: name: src: pkgs.writeScriptBin name (readTemplate subs src);
  };
}
