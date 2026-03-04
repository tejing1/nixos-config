{
  inputs,
  lib,
  my,
  ...
}:

let
  inherit (builtins)
    isPath
    length
    sort
  ;
  inherit (lib)
    mkOption
    path
    removePrefix
    types
  ;
  inherit (path)
    subpath
  ;

  nixos-release = "25.11"; # FIXME set elsewhere
in

{
  options = {
    my = {
      # flake.inputs = mkOption {}; # FIXME
      flake.modules = mkOption {
        type = types.listOf (types.addCheck types.path isPath);
        default = [];
      };
      # flake.specialArgs = mkOption {}; # FIXME
    };
  };

  config = {
    my.flake.files."flake.nix".expr = {
      save.exprs.inputs.literal = { # FIXME set elsewhere
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-${nixos-release}";

        home-manager.url = "github:nix-community/home-manager/release-${nixos-release}";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";

        nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
        home-manager-unstable.url = "github:nix-community/home-manager/master";
        home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
        mobile-nixos.url = "github:tejing1/mobile-nixos/tejingphone";
        mobile-nixos.flake = false;

        flake-parts.url = "github:hercules-ci/flake-parts";
        flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

        vieb-nix.url = "github:tejing1/vieb-nix";
        vieb-nix.inputs.nixpkgs.follows = "nixpkgs";

        flake-programdb.url = "github:tejing1/flake-programdb";

        flake-compat.url = "github:NixOS/flake-compat";
        flake-compat.flake = false;
      };
      save.body = {
        format.before = ''
          # This file is generated. (Yes, really.)
          # See ${removePrefix "${inputs.self}/" __curPos.file} for its definition.

        '';
        format.expr = {
          set.defs.inputs.saved = "inputs";
          set.defs.outputs.lambda.var = "inputs";
          set.defs.outputs.lambda.body = {
            app.func = {
              sel.from.var = "inputs";
              sel.attr = [ "flake-parts" "lib" "mkFlake" ];
            };
            app.arg = [ "main" "module" ];
            app.args.main = {
              set.inh.inputs = null;
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
                app.args.items.literal = sort (x: y: # FIXME do this in 'apply' on the option?
                  let
                    x' = subpath.components (path.removePrefix my.flake.root x);
                    xl = length x';
                    y' = subpath.components (path.removePrefix my.flake.root y);
                    yl = length y';
                  in
                    if xl != yl && (xl < 2 || yl < 2) then
                      xl < yl
                    else
                      x' < y'
                ) my.flake.modules;
              };
              set.defs.my.literal.flake.modules = [ (my.flake.root + "/fpentry.nix") ];
            };
          };
        };
      };
    };
  };
}
