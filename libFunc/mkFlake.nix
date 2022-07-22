{ lib, pkgs, ... }:
let
  inherit (builtins) mapAttrs concatMap attrValues toJSON listToAttrs;
  inherit (pkgs) runCommand;
  inherit (lib) nameValuePair concatStrings mapAttrsToList;
  inherit (lib.strings) escapeNixIdentifier escapeNixString;

  cleanNode = flake:
    let spec = {type="path";path=flake.sourceInfo.outPath;inherit (flake.sourceInfo) narHash;};
    in {inputs = mapAttrs (_: cleanNode) flake.inputs;locked = spec;original = spec;};
  flattenNode = prefix: node:
    let
      ids = mapAttrs (n: v: (flattenNode (prefix + "-" + n) v).name) node.inputs;
      nod = concatMap (x: x) (attrValues (mapAttrs (n: v: (flattenNode (prefix + "-" + n) v).value) node.inputs));
    in nameValuePair prefix ([ (nameValuePair prefix (node // { inputs = ids; })) ] ++ nod);
in

flakeInputs:
let
  inputsCode = "{${concatStrings (
    mapAttrsToList (n: v: "${escapeNixIdentifier n}.url=${escapeNixString "path:${v.sourceInfo.outPath}?narHash=${v.sourceInfo.narHash}"};") flakeInputs
  )}}";
  rootNode = {inputs = mapAttrs (_: cleanNode) flakeInputs;};
  lockJSON = toJSON {
    version = 7;
    root = "self";
    nodes = listToAttrs (flattenNode "self" rootNode).value;
  };
in

outputsCode:

runCommand "source" {} ''
mkdir -p $out
cat <<"EOF" >$out/flake.nix
{inputs=${inputsCode};outputs=${outputsCode};}
EOF
cat <<"EOF" >$out/flake.lock
${lockJSON}
EOF
''
