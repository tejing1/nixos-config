{ inputs, lib, ... }:

let
  inherit (builtins) listToAttrs mapAttrs;
  inherit (lib) hasPrefix hasInfix zipListsWith nameValuePair splitString removePrefix;

  flakeNixInputs = (import (inputs.self + "/flake.nix")).inputs;

  # Woefully incomplete. Only intended to handle 2 cases correctly:
  # 1. "github:owner/repo"
  # 2. "github:owner/repo/ref"
  expandFlakeUrl = url:
    assert hasPrefix "github:" url;
    assert ! hasInfix "?" url;
    { type = "github"; } //
    listToAttrs (zipListsWith nameValuePair [ "owner" "repo" "ref" ] (
      splitString "/" (removePrefix "github:" url)
    ));
  canonicalizeInputSpec = spec: if spec ? url then removeAttrs spec [ "url" ] // expandFlakeUrl spec.url else spec;
in
{
  _module.args.inputSpecs = mapAttrs (_: canonicalizeInputSpec) flakeNixInputs;
}
