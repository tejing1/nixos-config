{ lib, ... }:
with lib;

{
  # undo default shellAliases
  environment.shellAliases = genAttrs [ "l" "ll" "ls" ] (_: mkOverride 999 null);
}
