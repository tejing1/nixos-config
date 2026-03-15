{
  inputs,
  lib,
  my,
  options,
  ...
}:

let
  inherit (builtins)
    elem
    filter
    foldl'
    genericClosure
    groupBy
    isPath
    length
    mapAttrs
    pathExists
    readDir
    sort
  ;
  inherit (lib)
    attrsToList
    concatMapStringsSep
    hasSuffix
    listToAttrs
    mkOption
    optionalAttrs
    path
    removePrefix
    subtractLists
    types
    unique
    warnIf
  ;
  inherit (my.lib)
    nixLiteralType
    nixExprType
    pathType
  ;
  inherit (path)
    subpath
  ;

  separateRepeats = foldl' (acc: e:
    if ! elem e acc.uniques then
      acc // { uniques = acc.uniques ++ [ e ]; }
    else if ! elem e acc.repeats then
      acc // { repeats = acc.repeats ++ [ e ]; }
    else
      acc
  ) { uniques = []; repeats = []; };
in

{
  options = {
    my.flake = {
      inputs = mkOption {
        type = types.attrsOf nixLiteralType;
        default = {};
      };
      modules = mkOption {
        type = types.listOf pathType;
        default = [];
        apply = modules: let
          lessThan = x: y: let
            x' = subpath.components (path.removePrefix my.flake.root x);
            xl = length x';
            y' = subpath.components (path.removePrefix my.flake.root y);
            yl = length y';
          in
            if xl != yl && (xl < 2 || yl < 2) then
              xl < yl
            else
              x' < y';
          inherit (separateRepeats (sort lessThan modules)) uniques repeats;
          importGraph = listToAttrs (map ({file, value}: { name = file; value = map toString value; }) options.my.flake.modules.definitionsWithLocations);
          rootedList = map (x: my.flake.root + removePrefix (toString my.flake.root) x.key) (genericClosure {
            startSet = [ { key = toString (my.flake.root + "/fpentry.nix"); } ];
            operator = item: map (key: { inherit key; }) (importGraph.${item.key} or []);
          });
          unrootedList = lib.subtractLists rootedList uniques;
        in
          warnIf (length repeats > 0) "Same path(s) added to my.flake.modules more than once: ${concatMapStringsSep " " (path.removePrefix my.flake.root) repeats}" (
            warnIf (length unrootedList > 0) "Some path(s) in my.flake.modules are not in the closure of the root module: ${concatMapStringsSep " " (path.removePrefix my.flake.root) unrootedList}"
              uniques
          );
      };
      specialArgs = mkOption {
        type = types.attrsOf nixExprType;
        default = {};
      };
    };
  };

  config = {
    my.flake.inputs = {
      flake-parts.url = "github:hercules-ci/flake-parts";
      flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";


      # FIXME set elsewhere
      home-manager.url = "github:nix-community/home-manager/release-${my.nixpkgs.release}";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";

      home-manager-unstable.url = "github:nix-community/home-manager/master";
      home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

      flake-programdb.url = "github:tejing1/flake-programdb";
    };

    my.flake.files."flake.nix".expr = {
      format.before = ''
        # This file is generated. (Yes, really.)
        # See ${removePrefix "${inputs.self}/" __curPos.file} for its definition.

      '';
      format.expr = {
        set.defs.inputs.literal = my.flake.inputs;
        set.defs.outputs.lambda.var = "inputs";
        set.defs.outputs.lambda.body = {
          app.func = {
            sel.from.var = "inputs";
            sel.attrpath = [ "flake-parts" "lib" "mkFlake" ];
          };
          app.arg = [ "main" "module" ];
          app.args.main = {
            set.inh.inputs = null;
            set.defs = optionalAttrs (my.flake.specialArgs != {}) { specialArgs.set.defs = my.flake.specialArgs; };
          };
          app.args.module = {
            set.defs.imports = {
              app.func = {
                sel.from.var = "builtins";
                sel.attr = "filter";
              };
              app.arg = [ "pred" "items" ];
              app.args.pred = {
                sel.from.var = "builtins";
                sel.attr = "pathExists";
              };
              app.args.items.literal = [ (my.flake.root + "/fpentry.nix") ] ++ my.flake.modules;
            };
          };
        };
      };
    };

    my.lib.listFlakePartsModules = dir: let
      byType = mapAttrs (n: map (x: x.name)) (groupBy (x: x.value) (attrsToList (readDir dir)));
      filteredRegulars =
        map (n: dir + "/${n}") (
          subtractLists [
            "fpentry.nix"
            "flake.nix"
            "default.nix"
            "shell.nix"
            "overlay.nix"
            "package.nix"
          ] (
            filter (hasSuffix ".nix") (byType.regular or [])
          )
        );
      filteredDirectories =
        filter pathExists (
          map (n: dir + "/${n}/fpentry.nix") (byType.directory or [])
        );
    in
      filteredRegulars ++ filteredDirectories;
  };
}
