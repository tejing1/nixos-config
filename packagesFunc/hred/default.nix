{
  my.pkgsFunc = pkgs: {
    hred = pkgs.callPackage ./package.nix {};
  };
}
