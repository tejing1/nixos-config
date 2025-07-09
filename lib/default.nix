{ config, lib, my, ...}@args:

# In order for mylib bootstrapping to work, all modules under this
# directory must do the following:

# - If they set 'my.lib', its value can rely only on the argument
#   'inputs' and the part of 'my.lib' set by modules under this
#   directory.

# - If they calculate imports, they may only use
#   'mylib.listImportablePathsExcept'

# It does not matter what other options they set, or what they rely on
# to do so.

let
  inherit (lib)
    evalModules
    mkOption
    types
    optional
  ;
  inherit (types)
    lazyAttrsOf
    unspecified
  ;

  # What module files are we importing at this stage of (pre-)eval?
  modules =
    if args ? mylib
    then args.mylib.listImportablePathsExcept ./. [ "default" ]
    else [
      # Dependency closure of 'listImportablePathsExcept'
      ./listImportablePathsExcept.nix
      ./getImportableExcept.nix
      ./getImportable.nix
    ];

  # Are we in one of the pre-evaluation stages?
  pre-eval = ! args ? flake-parts-lib;

  # Imported during pre-evaluation to compensate for missing modules
  crutchmodule = { config, ... }: {
    # Gives module system errors better location information
    _file = __curPos.file + " (crutchmodule)";

    # Allows undeclared options to be set, as long as you don't try to
    # evaluate them
    freeformType = unspecified;

    # Normally set elsewhere, but needed during pre-eval
    _module.args.my = config.my;
  };
in

{
  imports = modules ++ optional pre-eval crutchmodule;

  options = {
    my.lib = mkOption {
      type = lazyAttrsOf unspecified;
    };
  };

  config = {
    flake.lib = my.lib;
  };
}
