{
  inputs,
  my,
  ...
}:

let

  inherit (builtins)
    fromJSON
    readFile
  ;

in

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

    my.flake.files."shell.nix".expr = {
      sel.from.saved = "thisFlake";
      sel.attr = "shellNix";
    };

    my.flake.exprs.thisFlake = {
      app.func.saved = "invokeFlakeCompat";
      app.arg =
        if builtins.functionArgs my.flake.exprsEvaluated.invokeFlakeCompat ? copySourceTreeToStore then
          # Lix variant
          {
            set.defs.src.path = my.flake.root;
            set.defs.copySourceTreeToStore.literal = false;
            set.defs.useBuiltinsFetchTree = {
              has.expr.var = "builtins";
              has.attr = "fetchTree";
            };
          }
        else
          # Edolstra variant
          {
            set.defs.src.set.defs.outPath = {
              app.func.var = "toString";
              app.arg.path = my.flake.root;
            };
          };
    };

    my.flake.exprs.invokeFlakeCompat = let
      lockFile = fromJSON (readFile (my.flake.root + "/flake.lock"));
      inherit (lockFile.nodes.${lockFile.nodes.${lockFile.root}.inputs.flake-compat}) locked;
    in {
      app.func.var = "import";
      app.arg = {
        github = {
          app.func.var = "fetchTarball";
          app.arg.literal = {
            url = "https://github.com/${locked.owner}/${locked.repo}/archive/${locked.rev}.tar.gz";
            sha256 = locked.narHash;
          };
        };
        tarball = {
          app.func.var = "fetchTarball";
          app.arg.literal = {
            url = locked.url;
            sha256 = locked.narHash;
          };
        };
      }.${locked.type} or (throw "Could not derive fetch expression from lockfile node");
    };

    my.flake.inputs.flake-compat = {
      # Lix variant
      #url = "https://git.lix.systems/lix-project/flake-compat/archive/main.tar.gz";
      # Edolstra variant
      url = "github:NixOS/flake-compat";
      flake = false;
    };

  };
}
