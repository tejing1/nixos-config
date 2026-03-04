{
  config,
  lib,
  my,
  ...
}:

let
  inherit (builtins)
    readFile
    length
  ;
  inherit (lib)
    head
    attrsToList
    stringLength
    mapAttrs'
    nameValuePair
    foldl
    imap1
    fixedWidthNumber
    mkOption
    types
    mkMerge
    mkIf
    optionalString
    path
  ;
  inherit (types)
    attrsOf
    attrTag
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

        [[ ! "$path" =~ (^|/)(|\.|\.\.)(/|$) ]] || die "paths must not begin or end with a '/', contain '//', or involve '.' or '..': $path"
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

in

{
  options = {
    my.flake.files = mkOption {
      type = attrsOf (attrTag { # FIXME check attr names are in canonical form
        norm = mkOption { type = lines; };
        exec = mkOption { type = lines; };
        link = mkOption { type = str; };
        expr = mkOption { type = types.raw; }; # FIXME make this type
        tree = mkOption {
          type = attrsOf (attrTag { # FIXME check attr names are in canonical form
            norm = mkOption { type = lines; };
            exec = mkOption { type = lines; };
            link = mkOption { type = str; };
            expr = mkOption { type = types.raw; }; # FIXME make this type
          });
          default = {};
          apply = x: if x == {} then throw "A generated tree cannot be empty!" else x;
        };
      });
      default = {};
    };
  };

  config = {
    my.flake.modules = listImportablePathsExcept ./. [ "default" ];

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

          echo Installing pre-commit hook
          hookInstallLocation="$(git rev-parse --git-path hooks/pre-commit)"
          nix build ${preCommitHook} -o "$hookInstallLocation"
        '';
      };
    };
  };
}
