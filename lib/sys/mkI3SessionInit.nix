{ lib, my, pkgs, ... }:
let
  inherit (builtins)
    head
    tail
    length
    all
    elemAt
    concatMap
    toFile
    toJSON
    isString
    isAttrs
    isFloat
    isList
    concatStringsSep
    attrValues
    mapAttrs
  ;
  inherit (lib)
    genAttrs
    drop
    foldr
    flip
    escapeShellArg
  ;
  inherit (pkgs)
    resholveScript
  ;

  genericNode = {
    border = "pixel";
    floating = "auto_off";
    marks = [];
    type = "con";
  };

  leafNode = genericNode // {
    current_border_width = 2;
    geometry = {
      height = 432;
      width = 720;
      x = 0;
      y = 0;
    };
  };

  containerTypes = [
    "splith"
    "splitv"
    "tabbed"
    "stacked"
  ];

  # names are the possible list heads, values are functions from the tail of the list to the json/exec info
  nodes =
    genAttrs containerTypes (n: content:
      assert all (x: isAttrs x || isFloat x || isList x) content;
      {
        json = genericNode // {
          layout = n;
          nodes = processNodes (map (x: if isList x then (nodes.${head x} (tail x)).json else x) content);
        };
        exec = concatMap (x: if isList x then (nodes.${head x} (tail x)).exec else []) content;
      }
    ) //
    {
      win = content: {
        json = leafNode // {
          name = elemAt content 0;
          swallows = [(elemAt content 1)];
        };
        exec = drop 2 content;
      };
    };

  # Filter a list of nodes for floats, and use them as anchors to calculate and add percent values.
  processNodes = nodes: (foldr processNode { rbound = 1.0; unspaced = []; spaced = []; } ([ 0.0 ] ++ nodes)).spaced;
  processNode = e: acc:
    if isFloat e then
      assert length acc.unspaced > 0;
      {
        rbound = e;
        unspaced = [];
        spaced = map (x: x // { percent = (acc.rbound - e) / length acc.unspaced; }) acc.unspaced ++ acc.spaced;
      }
    else
      {
        inherit (acc) rbound spaced;
        unspaced = [ e ] ++ acc.unspaced;
      }
  ;

  # Produces a string to be added to i3 config in order to initialize the described session
  mkI3SessionInit = { initialWorkspace, workspaceLayouts }: ''
    exec --no-startup-id ${
      resholveScript "i3-session.sh" {
        interpreter = "${pkgs.bash}/bin/bash";
        inputs = attrValues {
          inherit (pkgs) i3;
        };} ''
        i3-msg ${escapeShellArg (concatStringsSep "\n" (
          attrValues ((flip mapAttrs) workspaceLayouts (workspace: content:
            let  inherit (nodes.${head content} (tail content)) json exec; in ''
              workspace ${workspace}
              append_layout ${toFile "layout.json" (toJSON json)}
              ${concatStringsSep "\n" (map (c: "exec --no-startup-id ${c}") exec)}''))
          ++ [ "workspace ${initialWorkspace}" ]
        ))}''}'';
in mkI3SessionInit
