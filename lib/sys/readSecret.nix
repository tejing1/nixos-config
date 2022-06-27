{ pkgs, ... }:
let
  inherit (builtins) readFile;
in

default: file:
let
  # This should not be this hard, but readFile and nix strings just
  # refuse to deal with nulls, so this is seems to be the only way to
  # do this.
  locked = import (pkgs.runCommand "test-result" { inherit file; } ''
    if diff <(head -c10 "$file") <(echo -ne '\x00GITCRYPT\x00'); then echo true > $out; else echo false > $out; fi
  '');
in
if locked then default else readFile file
