{ ... }:
{
  imports = with builtins;
    let
      filterAttrs = pred: set: listToAttrs (filter (x: pred x.name x.value) (map (n: { name = n; value = getAttr n set; }) (attrNames set)));
    in
      map (n: ./. + "/${n}") (attrNames (filterAttrs (
        n: v: (
          v == "directory" &&
          pathExists (./. + "/${n}/default.nix")
        ) || (
          v == "regular" &&
          isList (match ".+\\.nix" n) &&
          n != "default.nix"
        )) (readDir ./.)));
}
