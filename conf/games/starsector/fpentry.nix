{
  my.nixpkgs.allowUnfreePackages = [
    "starsector"
  ];

  users.tejing.hm.cfg = { my, ... }: {
    home.packages = [ my.pkgs.starsector ];
  };

  perPkgs = { my, ... }: {
    my.pkgs.starsector = my.pkgs.callPackage ./package.nix {};
  };
}
