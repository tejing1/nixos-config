{ flake-parts-lib, lib, my, mylib, self, ... }:

let
  inherit (builtins) elem;
  inherit (flake-parts-lib) mkTransposedPerSystemModule;
  inherit (lib) mkOption types filterAttrs mkMerge;
  inherit (types) functionTo attrsOf;
in

{
  imports = mylib.listImportablePathsExcept ./. [ "default" ] ++ [
    # Add a non-standard system-spaced flake output for packages built against nixpkgs unstable
    (mkTransposedPerSystemModule {
      name = "packagesUnstable";
      option = mkOption {
        type = types.lazyAttrsOf types.package;
        default = {};
      };
      file = /. + __curPos.file;
    })
  ];

  options = {
    # Individual package modules define this
    my.pkgsFunc = mkOption {
      type = functionTo (attrsOf types.package);
      default = {};
    };
  };

  config = mkMerge [
    # Provide packages for internal use
    {
      perSystem = { my, pkgs, pkgsUnstable, ... }: {
        options = {
          my.pkgs = mkOption {
            type = attrsOf types.package;
            readOnly = true;
          };
          my.pkgsUnstable = mkOption {
            type = attrsOf types.package;
            readOnly = true;
          };
        };

        config = {
          my.pkgs = my.pkgsFunc pkgs;
          my.pkgsUnstable = my.pkgsFunc pkgsUnstable;
        };
      };
    }

    # Provide packages for external use
    {
      # Filter by meta.platforms so we don't expose non-working flake outputs
      flake.packagesFunc = pkgs: filterAttrs (n: p: ! p ? meta || ! p.meta ? platforms || elem pkgs.system p.meta.platforms) (my.pkgsFunc pkgs);

      # Use self.packagesFunc here rather than my.pkgsFunc, because we want the filtering
      # Also get our pkgs value directly from inputs, so we don't export local nixpkgs config
      perSystem = { inputs', ... }: {
        packages = self.packagesFunc inputs'.nixpkgs.legacyPackages;
        packagesUnstable = self.packagesFunc inputs'.nixpkgs-unstable.legacyPackages;
      };
    }
  ];
}
