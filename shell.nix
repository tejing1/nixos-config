let
  lockFile = builtins.fromJSON (builtins.readFile ./flake.lock);
  lockRoot = lockFile.nodes.${lockFile.root};
  inherit (lockFile.nodes.${lockRoot.inputs.flake-compat}) locked;
  flake-compat = import {
    tarball = fetchTarball {
      inherit (locked) url;
      sha256 = locked.narHash;
    };
    github = fetchTarball {
      url = "https://github.com/${locked.owner}/${locked.repo}/archive/${locked.rev}.tar.gz";
      sha256 = locked.narHash;
    };
  }.${locked.type} or (throw "Could not derive tarball url from lockfile node");
  mkArgNoCopy = flakePath:
    if builtins.functionArgs flake-compat ? copySourceTreeToStore
    then # Lix variant
      {
        src = flakePath;
        copySourceTreeToStore = false;
        useBuiltinsFetchTree = builtins ? fetchTree;
      }
    else # Edolstra variant
      {
        src.outPath = toString flakePath;
      };
  loadFlakeNoCopy = flakePath: flake-compat (mkArgNoCopy flakePath);
in (loadFlakeNoCopy ./.).shellNix
