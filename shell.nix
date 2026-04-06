# This file is generated.
# See dev/dev-shell.nix for its definition.

(
  import (
    fetchTarball {
      sha256 = "sha256-vNpUSpF5Nuw8xvDLj2KCwwksIbjua2LZCqhV1LNRDns=";
      url = "https://github.com/NixOS/flake-compat/archive/5edf11c44bc78a0d334f6334cdaf7d60d732daab.tar.gz";
    }
  ) {
    src.outPath = toString ./.;
  }
).shellNix
