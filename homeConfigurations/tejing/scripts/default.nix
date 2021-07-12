{ pkgs, lib, my, ... }:
let
  inherit (builtins) mapAttrs readDir;
  inherit (lib) filterAttrs hasSuffix mkOption types;
  inherit (my.lib) templateScriptBin;

  scriptPkgs = mapAttrs (n: _: templateScriptBin (pkgs // my.pkgs) n (./. + "/${n}"))
    (filterAttrs (n: v:
      v == "regular" &&
      ! hasSuffix ".nix" n
    ) (readDir ./.));
in
{
  options = {
    my.pkgs = mkOption {
      type = types.unspecified;
      description = "My scripts (package form)";
      visible = false;
      readOnly = true;
    };
    my.scripts = mkOption {
      type = types.unspecified;
      description = "My scripts (file form)";
      visible = false;
      readOnly = true;
    };
  };
  config = {
    my.pkgs = scriptPkgs // { "xorg.xset" = pkgs.xorg.xset; }; # FIXME: ugly hack. should make the template code handle the general case
    my.scripts = mapAttrs (n: v: "${v}/bin/${n}") scriptPkgs;
  };
}
