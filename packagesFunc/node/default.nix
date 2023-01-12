{ pkgs, ... }:
let
  inherit (pkgs.lib) extends;
  nodejs = pkgs.${builtins.readFile ./node_package};

  nodePackages = import ./node-composition.nix {
    inherit pkgs nodejs;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  overrides = import ./overrides.nix { inherit pkgs nodejs; };

  finalPackages = extends overrides (_: nodePackages) finalPackages;

in finalPackages
