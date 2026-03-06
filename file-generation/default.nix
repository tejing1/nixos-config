{
  config,
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
    match
    readFile
    seq
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
    lines
    str
  ;
  inherit (my.lib)
    listImportablePathsExcept
    mkNixExpr
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
        expr = mkOption { type = types.raw; }; # FIXME make this type
        tree = mkOption {
          type = attrsOf (attrTag {
            norm = mkOption { type = lines; };
            exec = mkOption { type = lines; };
            link = mkOption { type = str; };
            expr = mkOption { type = types.raw; }; # FIXME make this type
          });
          default = {};
          apply = checkedTree "my.flake.files.<name>.tree";
        };
      });
      default = {};
      apply = checkedTree "my.flake.files";
    };
  };

  config = {
    my.flake.modules = listImportablePathsExcept ./. [ "default" ];

    my.flake.inputs = {
      flake-compat.url = "github:NixOS/flake-compat";
      flake-compat.flake = false;
    };

    perSystem = { pkgs, my, ... }: let
      regenPackage = pkgs.writeShellScriptBin "regen" (readFile ./regenerate-files.sh);

      preCommitHook = pkgs.writeShellScript "pre-commit" ''
        exec ${regenPackage}/bin/regen -i
      '';
    in {
      # FIXME probably rename this file. the dev shell shouldn't go in 'file-generation'
      devShells.default = pkgs.mkShellNoCC {
        packages = [ regenPackage ];
        passthru.generated-files = mkfile { inherit pkgs; toplevel = my.flake.root; writeManifest = true; } { tree = my.flake.files; };
        shellHook = pkgs.writeShellScript "install-pre-commit-hook" ''
          set -eu

          hookInstallLocation="$(git rev-parse --git-path hooks/pre-commit)"
          if [ -L "$hookInstallLocation" ]; then
            currentHookTarget="$(realpath "$hookInstallLocation")"
            if [ "$currentHookTarget" == ${preCommitHook} ]; then
              exit 0
            else
              echo -n "Updating pre-commit hook..."
              rm -- "$hookInstallLocation"
            fi
          elif [ -e "$hookInstallLocation" ]; then
            echo "Refusing to overwrite non-symlink pre-commit hook!"
            exit 1
          else
            echo -n "Installing pre-commit hook..."
          fi
          if nix-store --realise ${preCommitHook} --add-root "$hookInstallLocation" >/dev/null; then
            echo " Success."
          else
            echo " Failed!"
          fi
        '';
      };
    };
  };
}
