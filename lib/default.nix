{ ... }:
{
  imports = (import ./listimports.nix {}).my.listImports ./.;
}
