{
  my.pkgsFunc = pkgs: {
    starsector = pkgs.callPackage ./package.nix {};
  };
}
