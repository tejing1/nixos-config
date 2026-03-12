{
  perPkgs = { my, ... }: {
    my.pkgs.starsector = my.pkgs.callPackage ./package.nix {};
  };
}
