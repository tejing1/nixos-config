let
  inherit (lockFile.nodes.${lockFile.nodes.${lockFile.root}.inputs.flake-compat}) locked;
  flake-compat = import (
    {
      github = fetchTarball {
        sha256 = locked.narHash;
        url = "https://github.com/${locked.owner}/${locked.repo}/archive/${locked.rev}.tar.gz";
      };
      tarball = fetchTarball {
        inherit (locked) url;
        sha256 = locked.narHash;
      };
    }.${locked.type} or (throw "Could not derive tarball url from lockfile node")
  );
  lockFile = builtins.fromJSON (builtins.readFile ./flake.lock);
  thisFlake = if
    builtins.functionArgs flake-compat ? copySourceTreeToStore
  then
    flake-compat {
      copySourceTreeToStore = false;
      src = ./.;
      useBuiltinsFetchTree = builtins ? fetchTree;
    }
  else
    flake-compat {
      src.outPath = toString ./.;
    };
in
  thisFlake.shellNix
