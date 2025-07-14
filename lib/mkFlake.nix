{ lib, ... }:

let
  inherit (builtins) mapAttrs concatMap attrValues toJSON listToAttrs;
  inherit (lib) nameValuePair concatStrings mapAttrsToList;
  inherit (lib.strings) escapeNixIdentifier escapeNixString;

  cleanNode = flake:
    let spec = {type="path";path=flake.outPath;inherit (flake) narHash;};
        extra = if flake ? outputs then {} else { flake = false; };
    in {inputs = mapAttrs (_: cleanNode) (flake.inputs or {});locked = spec;original = spec;} // extra;
  flattenNode = prefix: node:
    let
      ids = mapAttrs (n: v: (flattenNode (prefix + "-" + n) v).name) node.inputs;
      nod = concatMap (x: x) (attrValues (mapAttrs (n: v: (flattenNode (prefix + "-" + n) v).value) node.inputs));
    in nameValuePair prefix ([ (nameValuePair prefix (node // { inputs = ids; })) ] ++ nod);
in

{
  perPkgs = { pkgs, ... }: {
    my.lib.mkFlake = flakeInputs: let
      inputsCode = "{${concatStrings (
        mapAttrsToList (n: v: "${escapeNixIdentifier n}.url=${escapeNixString "path:${v.sourceInfo.outPath}?narHash=${v.sourceInfo.narHash}"};") flakeInputs
      )}}";
      rootNode = {inputs = mapAttrs (_: cleanNode) flakeInputs;};
      lockJSON = toJSON {
        version = 7;
        root = "self";
        nodes = listToAttrs (flattenNode "self" rootNode).value;
      };
    in outputsCode: pkgs.runCommand "source" {} ''
      mkdir -p $out
      cat <<"EOF" >$out/flake.nix
      {inputs=${inputsCode};outputs=${outputsCode};}
      EOF
      cat <<"EOF" >$out/flake.lock
      ${lockJSON}
      EOF
    '';
  };
}
