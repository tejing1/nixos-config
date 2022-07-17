inputs@{nixpkgs, self, system, ...}:
{
  starsector = nixpkgs.legacyPackages.${system}.callPackage ./starsector.nix {};
}
