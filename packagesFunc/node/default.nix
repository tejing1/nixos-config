{ pkgs, ... }:

import ./node-composition.nix {
  inherit pkgs;
  inherit (pkgs) system;
}
