{ my, ... }:
let
  inherit (builtins) isBool;
  inherit (my.lib) repoLockedTestResult;

  isRepoLocked = import repoLockedTestResult;

in assert isBool isRepoLocked; isRepoLocked
