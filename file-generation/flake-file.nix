{
  inputs,
  lib,
  my,
  ...
}:

let
  inherit (builtins)
    elem
    foldl'
    isPath
    length
    sort
  ;
  inherit (lib)
    concatMapStringsSep
    mkOption
    optionalAttrs
    path
    removePrefix
    types
    unique
    warnIf
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
        type = types.attrsOf types.raw; # FIXME make a proper nix literal type
        default = {};
      };
      modules = mkOption {
        type = types.listOf (types.addCheck types.path isPath);
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
        in
          warnIf (length repeats > 0) "Same path added to my.flake.modules more than once: ${concatMapStringsSep " " (path.removePrefix my.flake.root) repeats}"
            uniques;
      };
      specialArgs = mkOption {
        type = types.attrsOf types.raw; # FIXME make a proper nix expression AST type
        default = {};
      };
    };
  };

  config = {
    my.flake.modules = [ (my.flake.root + "/fpentry.nix") ];

    my.flake.inputs = {
      flake-parts.url = "github:hercules-ci/flake-parts";
      flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";


      # FIXME set elsewhere
      home-manager.url = "github:nix-community/home-manager/release-${my.nixpkgs.release}";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";

      home-manager-unstable.url = "github:nix-community/home-manager/master";
      home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

      mobile-nixos.url = "github:tejing1/mobile-nixos/tejingphone";
      mobile-nixos.flake = false;

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
            sel.attr = [ "flake-parts" "lib" "mkFlake" ];
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
              app.args.items.literal = my.flake.modules;
            };
          };
        };
      };
    };
  };
}
