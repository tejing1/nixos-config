{ my, pkgs, ... }:
let
  inherit (builtins) readFile;

  readSecret = if my.lib.isRepoLocked then default: file: default else default: file: readFile file;
in
readSecret
