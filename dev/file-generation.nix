{
  config,
  flake-parts-lib,
  lib,
  my,
  ...
}:

let
  inherit (builtins)
    attrNames
    concatMap
    isList
    length
    mapAttrs
    match
    readFile
    seq
    toFile
  ;
  inherit (flake-parts-lib)
    mkPerSystemOption
  ;
  inherit (lib)
    attrsToList
    fixedWidthNumber
    foldl
    head
    imap1
    mapAttrs'
    mkIf
    mkMerge
    mkOption
    nameValuePair
    optionalString
    path
    stringLength
    types
  ;
  inherit (types)
    addCheck
    attrTag
    attrsOf
    lazyAttrsOf
    lines
    str
    raw
  ;
  inherit (my.lib)
    listFlakePartsModules
    mkNixExpr
    nixExprType
    nixEqsType
  ;

  getSingleton = list: if length list == 1 then head list else throw "List is not a singleton";
  switchAttrTag = branches: taggedattrs: ({name, value}: (branches.${name} or (throw "switchAttrTag: unknown tag ${name}")) value) (getSingleton (attrsToList taggedattrs));

  mkfile = { pkgs, filepath ? "", toplevel, writeManifest ? false }: switchAttrTag {
    norm = text: pkgs.writeTextFile { inherit text; name = baseNameOf filepath; executable = false; };
    exec = text: pkgs.writeTextFile { inherit text; name = baseNameOf filepath; executable = true; };
    link = linktarget: pkgs.runCommand (baseNameOf filepath) { inherit linktarget; } ''ln -s "$linktarget" $out'';
    expr = expr: pkgs.writeTextFile {
      name = baseNameOf filepath;
      executable = false;
      text = mkNixExpr {
        exprs = my.flake.exprs;
        eqs = my.flake.eqs;
        alreadyTypeChecked = true;
        inherit toplevel;
        targetfile = path.append toplevel filepath;
      } expr + "\n";
    };
    tree = content: let
      # appending '/' ensures sub-paths are always adjacent to their parent paths in the sorted order if both are present
      # we use this fact later to detect non-disjoint paths
      paths = attrsToList (mapAttrs' (n: v: nameValuePair (n + "/") v) content);
      width = stringLength (toString (length paths));
    in pkgs.runCommand (if filepath == "" then "generated-files" else baseNameOf filepath) {
      inherit writeManifest;
      env = foldl (x: y: x // y) {} ( imap1 (i: {name, value}: {
        "path_${fixedWidthNumber width i}" = name;
        "content_${fixedWidthNumber width i}" = mkfile { inherit pkgs toplevel; filepath = filepath + optionalString (filepath != "") "/" + name; } value;
      }) paths);
    } ''
      die() {
        echo "error: $1" >&2
        exit 1
      }
      mkdir -p "$out"
      prevpath=
      for pathvar in "''${!path_@}"; do
        path="''${!pathvar%/}" # strip the trailing '/' we added for sorting earlier
        contentvar="content_''${pathvar#path_}"
        content="''${!contentvar}"

        [[ ! "$path" =~ (^|/)(|\.|\.\.)(/|$) ]] || die "paths must not be empty, begin or end with a '/', contain '//', or involve '.' or '..': $path"
        if [ -n "$prevpath" ]; then
          [[ "$path" != "$prevpath"/* ]] || die "non-disjoint paths: $path, $prevpath"
          [[ "$prevpath" != "$path"/* ]] || die "non-disjoint paths: $prevpath, $path"
        fi
        prevpath="$path"

        if [ -n "$writeManifest" ]; then
          [ "$path" != ".generated-files-manifest" ] || die "path collides with manifest: $path"
          printf "%s\n" "$path" >> "$out/.generated-files-manifest"
        fi
        mkdir -p "$out/$(dirname "$path")"
        cp -PrT -- "$content" "$out/$path"
      done
    '';
  };

  checkedTree = opt: tree: seq (concatMap (path:
    if isList (match "([^/]*/)*(|\\.|\\.\\.)(/[^/]*)*" path) then
      throw "paths in ${opt} must not be empty, begin or end with a '/', contain '//', or involve '.' or '..': ${path}"
    else
      []
  ) (attrNames tree)) tree;

in

{
  options = {

    my.flake.files = mkOption {
      type = attrsOf (attrTag {
        norm = mkOption { type = lines; };
        exec = mkOption { type = lines; };
        link = mkOption { type = str; };
        expr = mkOption { type = nixExprType; };
        tree = mkOption {
          type = attrsOf (attrTag {
            norm = mkOption { type = lines; };
            exec = mkOption { type = lines; };
            link = mkOption { type = str; };
            expr = mkOption { type = nixExprType; };
          });
          default = {};
          apply = checkedTree "my.flake.files.<name>.tree";
        };
      });
      default = {};
      apply = checkedTree "my.flake.files";
    };

    my.flake.exprs = mkOption {
      type = attrsOf nixExprType;
      default = {};
    };

    my.flake.exprsRendered = mkOption {
      type = lazyAttrsOf str;
      readOnly = true;
    };

    my.flake.exprsEvaluated = mkOption {
      type = lazyAttrsOf raw;
      readOnly = true;
    };

    my.flake.eqs = mkOption {
      type = attrsOf nixEqsType;
      default = {};
    };

    perSystem = mkPerSystemOption ({ system, ... }: {
      options = {
        my.flake.generated-files = mkOption {
          type = types.package;
          readOnly = true;
          internal = true;
        };
      };
    });

  };

  config = {
    my.flake.exprsRendered = mapAttrs (n: v:
      mkNixExpr {
        exprs = my.flake.exprs;
        eqs = my.flake.eqs;
        alreadyTypeChecked = true;
      } v
    ) my.flake.exprs;

    my.flake.exprsEvaluated = mapAttrs (n: v:
      import (toFile "eval.nix" v)
    ) my.flake.exprsRendered;

    perPkgs = { pkgs, my, ... }: {
      my.pkgs.regenerate-files = pkgs.writeShellApplication {
        name = "regen";
        text = readFile ./regenerate-files.sh;

        runtimeInputs = [
          pkgs.coreutils
          pkgs.util-linux # getopt
          pkgs.ncurses    # tput
          pkgs.git        # git
          pkgs.gnused     # sed
          pkgs.findutils  # xargs
        ];

        # Override the default, since I set these in the code directly.
        bashOptions = [];
      };
    };

    perSystem = { pkgs, ... }: {
      my.flake.generated-files = mkfile {
        inherit pkgs;
        toplevel = my.flake.root;
        writeManifest = true;
      } {
        tree = my.flake.files;
      };
    };
  };
}
