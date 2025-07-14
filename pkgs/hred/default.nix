{
  perPkgs = { pkgs, ... }: {
    my.pkgs.hred = pkgs.callPackage ./package.nix {};
  };
}
