{ lib, ... }:
let
  inherit (lib) genAttrs mkOverride;
in

{
  # undo default shellAliases
  environment.shellAliases = genAttrs [ "l" "ll" "ls" ] (_: mkOverride 999 null);
}
