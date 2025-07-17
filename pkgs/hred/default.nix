{
  perPkgs = { my, ... }: {
    my.pkgs.hred = my.pkgs.callPackage ./package.nix {};
  };
}
