inputs@{ flake-utils, lib, my, nixpkgs, ... }:
let
  inherit (flake-utils.lib) defaultSystems;
  inherit (lib) genAttrs;
  inherit (my.lib) importAllExceptWithArg;
in

# do everything for each default system and collect results in an
# attrset so for example, a function in 'foo.nix' in this directory
# would be accessible as 'self.lib.sys.x86_64-linux.foo'
genAttrs defaultSystems
  (system:

    # include the system-agnotic lib, so we can just import one thing
    # as my.lib where we know the current system
    my.lib //

    # import everything in this directory
    importAllExceptWithArg ./. [ "default.nix" ] (
      inputs //
      {
        # pass a 'system' argument in case I want it.
        inherit system;

        pkgs = {
          inherit (nixpkgs.legacyPackages."${system}")
            # If you need it, add it, but ONLY builder functions.
            # Don't actually put packages here, as they won't get
            # overlays and nixpkgs config.  I wish nixpkgs exposed
            # these as a separate output.
            runCommand
            runCommandCC
            runCommandLocal
            writeTextFile
            writeText
            writeTextDir
            writeScript
            writeScriptBin
            symlinkJoin
            writeReferencesToFile
            writeDirectReferencesToFile
            resholveScript
            resholveScriptBin
            bash
          ;
        };

        # pass the final (merged) structure as my.lib
        my.lib = my.lib.sys."${system}";
      }
    )
  )
