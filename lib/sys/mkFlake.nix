{ lib, pkgs, ... }:
with builtins;
with pkgs;
with lib;
with lib.strings;

flakeInputs: outputsCode:
let
  inputsCode = "{${concatStrings (
    mapAttrsToList (n: v: "${escapeNixIdentifier n}.url=${escapeNixString "path:${v.sourceInfo.outPath}?narHash=${v.sourceInfo.narHash}"};") flakeInputs
  )}}";
  cleanNode = flake:
    let spec = {type="path";path=flake.sourceInfo.outPath;inherit (flake.sourceInfo) narHash;};
    in {inputs = mapAttrs (n: v: cleanNode v) flake.inputs;locked = spec;original = spec;};
  rootNode = {inputs = mapAttrs (n: cleanNode) flakeInputs;};
  flattenNode = prefix: node:
    let
      ids = mapAttrs (n: v: (flattenNode (prefix + "-" + n) v).name) node.inputs;
      nod = concatMap (x: x) (attrValues (mapAttrs (n: v: (flattenNode (prefix + "-" + n) v).value) node.inputs));
    in nameValuePair prefix ([ (nameValuePair prefix (node // { inputs = ids; })) ] ++ nod);
  lockJSON = toJSON {
    version = 7;
    root = "self";
    nodes = listToAttrs (flattenNode "self" rootNode).value;
  };
in
runCommand "source" {} ''
mkdir -p $out
cat <<"EOF" >$out/flake.nix
{inputs=${inputsCode};outputs=${outputsCode};}
EOF
cat <<"EOF" >$out/flake.lock
${lockJSON}
EOF
''
