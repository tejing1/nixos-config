{ pkgs, ... }:
let
  inherit (pkgs) runCommand;

  # This should not be this hard, but readFile and nix strings just
  # refuse to deal with nulls, so this seems to be the only way to do
  # it.
  repoLockedTestResult = pkgs.runCommand "test-result" { file = ./dummy.secret; } ''
    if diff <(head -c10 "$file") <(echo -ne '\x00GITCRYPT\x00'); then
      # file starts with ^@GITCRYPT^@
      echo true > $out
    else
      # file does not start with ^@GITCRYPT^@
      echo false > $out
    fi
  '';
in repoLockedTestResult
