{ ... }:
with builtins;
rec {
  my.attrsToList = set: map (n: { name = n; value = getAttr n set; }) (attrNames set);
  my.filterAttrs = pred: set: listToAttrs (filter (x: pred x.name x.value) (my.attrsToList set));
  my.mapAttrs = f: set: listToAttrs (map (x: { inherit (x) name; value = f x.name x.value; }) (my.attrsToList set));
  my.filterFiles = pred: path: map (n: path + "/${n}") (attrNames (my.filterAttrs pred (readDir path)));
  my.listImports = path: my.filterFiles (
    n: v: (
      v == "directory" &&
      pathExists (path + "/${n}/default.nix")
    ) || (
      v == "regular" &&
      isList (match ".+\\.nix" n) &&
      n != "default.nix"
    )) path;
}
