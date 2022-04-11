inputs@{nixpkgs, self, system, ...}:
import ./node-composition.nix { pkgs = nixpkgs.legacyPackages."${system}"; inherit system; }
