{
  inputs,
  my,
  ...
}:

{
  config = {
    flake = {
      inherit inputs;
    };

    perSystem = { pkgs, my, ... }: {
      devShells.default = let
        preCommitHook = pkgs.writeShellScript "pre-commit" ''
          exec ${my.pkgs.regenerate-files}/bin/regen -i
        '';
      in pkgs.mkShellNoCC {
        packages = [ my.pkgs.regenerate-files ];
        passthru.generated-files = my.flake.generated-files;
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

    my.flake.files.".generate-files".exec = ''
      #! /usr/bin/env bash

      if [ "$#" != 1 ]; then
        echo "Usage: $0 <where_to_output>"
        exit 1
      fi

      exec nix --extra-experimental-features nix-command build -f shell.nix default.generated-files -o "$1"
    '';

    my.flake.files.".envrc".norm = ''
      use nix
    '';

    my.flake.inputs = {
      flake-compat.url = "github:NixOS/flake-compat";
      flake-compat.flake = false;
    };

    my.flake.files."shell.nix".expr = {
      letin.defs.lockFile = {
        app.func = {
          sel.from.var = "builtins";
          sel.attr = "fromJSON";
        };
        app.arg = {
          app.func = {
            sel.from.var = "builtins";
            sel.attr = "readFile";
          };
          app.arg.path = my.flake.root + "/flake.lock";
        };
      };
      letin.inh.locked = {
        sel.from.var = "lockFile";
        sel.attrpath = [
          "nodes"
          {
            sel.from.var = "lockFile";
            sel.attrpath = [
              "nodes"
              {
                sel.from.var = "lockFile";
                sel.attr = "root";
              }
              "inputs"
              "flake-compat"
            ];
          }
        ];
      };
      letin.defs.flake-compat = {
        app.func.var = "import";
        app.arg = {
          sel.from = {
            set.defs.tarball = {
              app.func.var = "fetchTarball";
              app.arg = {
                set.inh.url.var = "locked";
                set.defs.sha256 = {
                  sel.from.var = "locked";
                  sel.attr = "narHash";
                };
              };
            };
            set.defs.github = {
              app.func.var = "fetchTarball";
              app.arg = {
                set.defs.url.string = [
                  "https://github.com/"
                  {
                    sel.from.var = "locked";
                    sel.attr = "owner";
                  }
                  "/"
                  {
                    sel.from.var = "locked";
                    sel.attr = "repo";
                  }
                  "/archive/"
                  {
                    sel.from.var = "locked";
                    sel.attr = "rev";
                  }
                  ".tar.gz"
                ];
                set.defs.sha256 = {
                  sel.from.var = "locked";
                  sel.attr = "narHash";
                };
              };
            };
          };
          sel.attr = {
            sel.from.var = "locked";
            sel.attr = "type";
          };
          sel.default = {
            app.func.var = "throw";
            app.arg.string = "Could not derive tarball url from lockfile node";
          };
        };
      };
      letin.defs.thisFlake = {
        branch.cond = {
          has.expr = {
            app.func = {
              sel.from.var = "builtins";
              sel.attr = "functionArgs";
            };
            app.arg.var = "flake-compat";
          };
          has.attr = "copySourceTreeToStore";
        };
        branch.truecase = {
          app.func.var = "flake-compat";
          app.arg = {
            set.defs.src.path = my.flake.root;
            set.defs.copySourceTreeToStore.var = "false";
            set.defs.useBuiltinsFetchTree = {
              has.expr.var = "builtins";
              has.attr = "fetchTree";
            };
          };
        };
        branch.falsecase = {
          app.func.var = "flake-compat";
          app.arg = {
            set.defs.src.set.defs.outPath = {
              app.func.var = "toString";
              app.arg.path = my.flake.root;
            };
          };
        };
      };
      letin.body = {
        sel.from.var = "thisFlake";
        sel.attr = "shellNix";
      };
    };
  };
}
