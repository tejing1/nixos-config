{
  perPkgs = { pkgs, ... }: {
    my.pkgs.starsector = pkgs.callPackage ./package.nix {};
  };
}
