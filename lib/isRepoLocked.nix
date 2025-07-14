let
  inherit (builtins) isBool;
in

{
  perPkgs = { my, ... }: {
    my.lib.isRepoLocked = (x: assert isBool x; x) (import my.lib.repoLockedTestResult);
  };
}
