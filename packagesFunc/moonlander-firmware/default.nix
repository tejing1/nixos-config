{
  my.pkgsFunc = pkgs: {
    moonlander-firmware = pkgs.callPackage ./package.nix {};
  };
}
